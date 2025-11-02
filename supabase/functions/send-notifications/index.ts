import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const FIREBASE_SERVER_KEY = "AAAA_a_r-aA:APA91bH-1-2-3-4-5-6-7-8-9-0";
const FCM_URL = "https://fcm.googleapis.com/fcm/send";

const morningMessages = [
  "Good morning! Time to crush your workout today!",
  "Rise and shine! A morning workout sets the tone for a great day.",
  "Wake up, work out, be happy. Let's get moving!",
];

const eveningMessages = [
  "Don't forget to pack your gym bag for tomorrow!",
  "A good night's sleep is crucial for muscle recovery. Rest up!",
  "Success isn't given, it's earned. See you at the gym tomorrow!",
];

const sleepMessages = [
  "Rest is just as important as the workout. Sweet dreams!",
  "Your muscles are rebuilding. Get some quality sleep.",
  "Dream big, train hard. Good night!",
];

function getRandomMessage(messages: string[]): string {
  return messages[Math.floor(Math.random() * messages.length)];
}

async function sendNotification(title: string, body: string) {
  const payload = {
    to: "/topics/all",
    notification: {
      title,
      body,
    },
  };

  const response = await fetch(FCM_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `key=${FIREBASE_SERVER_KEY}`,
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const errorData = await response.json();
    console.error("Failed to send notification:", errorData);
  }
}

serve(async (req: Request) => {
  const url = new URL(req.url);
  const time = url.searchParams.get("time");

  let title = "";
  let body = "";

  switch (time) {
    case "morning":
      title = "Morning Motivation";
      body = getRandomMessage(morningMessages);
      break;
    case "evening":
      title = "Evening Reminder";
      body = getRandomMessage(eveningMessages);
      break;
    case "sleep":
      title = "Sleep Well";
      body = getRandomMessage(sleepMessages);
      break;
    default:
      return new Response("Invalid time parameter", { status: 400 });
  }

  await sendNotification(title, body);

  return new Response(`Notification sent for ${time}`, {
    headers: { "Content-Type": "application/json" },
  });
});
