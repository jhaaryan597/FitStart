import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// V1 API credentials
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID')!
const FIREBASE_CLIENT_EMAIL = Deno.env.get('FIREBASE_CLIENT_EMAIL')!
const FIREBASE_PRIVATE_KEY = Deno.env.get('FIREBASE_PRIVATE_KEY')!

// Helper to get OAuth2 access token for V1 API
async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  
  const header = {
    alg: "RS256",
    typ: "JWT"
  }
  
  const claimSet = {
    iss: FIREBASE_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  }
  
  const headerBase64 = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const claimSetBase64 = btoa(JSON.stringify(claimSet)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const signatureInput = `${headerBase64}.${claimSetBase64}`
  
  // Import the private key
  const privateKeyPem = FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
  const pemContent = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  
  const binaryDer = Uint8Array.from(atob(pemContent), c => c.charCodeAt(0))
  
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  )
  
  // Sign the JWT
  const signatureBuffer = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(signatureInput)
  )
  
  const signatureArray = new Uint8Array(signatureBuffer)
  const signatureBase64 = btoa(String.fromCharCode(...signatureArray))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
  
  const jwt = `${signatureInput}.${signatureBase64}`
  
  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  
  const tokenData = await tokenResponse.json()
  
  if (!tokenData.access_token) {
    throw new Error(`Failed to get access token: ${JSON.stringify(tokenData)}`)
  }
  
  return tokenData.access_token
}

serve(async (req) => {
  try {
    // Verify request method
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), {
        status: 405,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { title, body, data, target_type = 'all', user_ids = [] } = await req.json()

    // Validate required fields
    if (!title || !body) {
      return new Response(JSON.stringify({ error: 'Title and body are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    let fcmPayload: any = {
      priority: "high",
      notification: {
        title: title,
        body: body,
        sound: "default",
        icon: "@mipmap/ic_launcher"
      },
      data: data || {},
    }

    let response: any
    let results: any = {}

    // Send to all users via topic
    if (target_type === 'all') {
      // Get OAuth2 access token
      const accessToken = await getAccessToken()
      
      // V1 API message format
      const message = {
        message: {
          topic: 'all',
          notification: {
            title: title,
            body: body,
          },
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              icon: '@mipmap/ic_launcher',
            },
          },
          data: data || {},
        }
      }
      
      response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${accessToken}`,
          },
          body: JSON.stringify(message),
        }
      )

      results = await response.json()
      
      return new Response(JSON.stringify({ 
        success: response.ok,
        target: 'all_users',
        ...results 
      }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Send to specific users
    if (target_type === 'specific' && user_ids.length > 0) {
      // Get OAuth2 access token
      const accessToken = await getAccessToken()
      
      // Create Supabase client
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      )

      // Get FCM tokens for specific users
      const { data: profiles, error } = await supabaseClient
        .from('profiles')
        .select('fcm_token')
        .in('id', user_ids)
        .not('fcm_token', 'is', null)

      if (error) {
        throw new Error(`Failed to fetch user tokens: ${error.message}`)
      }

      const tokens = profiles.map((p: any) => p.fcm_token)
      
      if (tokens.length === 0) {
        return new Response(JSON.stringify({ 
          success: false,
          error: 'No valid FCM tokens found for specified users'
        }), {
          status: 400,
          headers: { 'Content-Type': 'application/json' },
        })
      }

      // Send to each token individually with V1 API
      const sendResults = []
      for (const token of tokens) {
        const message = {
          message: {
            token: token,
            notification: {
              title: title,
              body: body,
            },
            android: {
              priority: 'high',
              notification: {
                sound: 'default',
                icon: '@mipmap/ic_launcher',
              },
            },
            data: data || {},
          }
        }
        
        const tokenResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${accessToken}`,
            },
            body: JSON.stringify(message),
          }
        )
        
        const result = await tokenResponse.json()
        sendResults.push(result)
      }
      
      return new Response(JSON.stringify({ 
        success: true,
        target: 'specific_users',
        users_count: tokens.length,
        results: sendResults
      }), {
        headers: { 'Content-Type': 'application/json' },
      })
    }

    return new Response(JSON.stringify({ 
      error: 'Invalid target_type or missing user_ids' 
    }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (error) {
    console.error('Error sending notification:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    return new Response(JSON.stringify({ 
      success: false,
      error: errorMessage 
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
