import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';
import 'package:FitStart/components/reusable/reusable_widgets.dart';

/// Example screen demonstrating all reusable components
/// This is a reference implementation showing best practices
class ExampleResponsiveScreen extends StatefulWidget {
  const ExampleResponsiveScreen({Key? key}) : super(key: key);

  @override
  State<ExampleResponsiveScreen> createState() =>
      _ExampleResponsiveScreenState();
}

class _ExampleResponsiveScreenState extends State<ExampleResponsiveScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  List<String> _items = [];
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
          _items.add('Item ${_items.length + 1}');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added successfully!')),
        );
        _nameController.clear();
        _emailController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: CustomAppBar(
        title: "Responsive Example",
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: ResponsiveContainer(
        padding: ResponsiveUtils.padding(context, all: 16),
        child: _isLoading
            ? const LoadingIndicator(message: "Processing...")
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchSection(),
                    ResponsiveSpacing(size: 24),
                    _buildFormSection(),
                    ResponsiveSpacing(size: 24),
                    _buildGridSection(),
                    ResponsiveSpacing(size: 24),
                    _buildItemsList(),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _items.add('Item ${_items.length + 1}');
          });
        },
        backgroundColor: primaryColor500,
        child: const Icon(Icons.add, color: colorWhite),
      ),
    );
  }

  Widget _buildSearchSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Search Example",
            style: subTitleTextStyle.copyWith(
              fontSize: ResponsiveUtils.fontSize(context, 16),
            ),
          ),
          ResponsiveSpacing(size: 12),
          CustomSearchBar(
            controller: _searchController,
            hintText: "Search items...",
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onClear: () {
              _searchController.clear();
              setState(() {
                _searchQuery = "";
              });
            },
            showClearButton: _searchQuery.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return CustomCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: "Form Example",
              icon: Icons.edit,
              padding: EdgeInsets.zero,
            ),
            ResponsiveSpacing(size: 16),
            CustomTextField(
              controller: _nameController,
              labelText: "Name",
              hintText: "Enter your name",
              prefixIcon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            ResponsiveSpacing(size: 16),
            CustomTextField(
              controller: _emailController,
              labelText: "Email",
              hintText: "Enter your email",
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            ResponsiveSpacing(size: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: "Submit",
                    onPressed: _handleSubmit,
                    type: ButtonType.primary,
                    size: ButtonSize.medium,
                    icon: Icons.check,
                  ),
                ),
                ResponsiveSpacing(size: 12, axis: Axis.horizontal),
                Expanded(
                  child: CustomButton(
                    text: "Cancel",
                    onPressed: () {
                      _nameController.clear();
                      _emailController.clear();
                    },
                    type: ButtonType.outline,
                    size: ButtonSize.medium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Button Variations",
          icon: Icons.touch_app,
        ),
        ResponsiveSpacing(size: 12),
        ResponsiveGrid(
          mobileColumns: 2,
          tabletColumns: 3,
          desktopColumns: 4,
          spacing: 12,
          runSpacing: 12,
          children: [
            CustomButton(
              text: "Primary",
              onPressed: () {},
              type: ButtonType.primary,
              size: ButtonSize.small,
            ),
            CustomButton(
              text: "Secondary",
              onPressed: () {},
              type: ButtonType.secondary,
              size: ButtonSize.small,
            ),
            CustomButton(
              text: "Outline",
              onPressed: () {},
              type: ButtonType.outline,
              size: ButtonSize.small,
            ),
            CustomButton(
              text: "Text",
              onPressed: () {},
              type: ButtonType.text,
              size: ButtonSize.small,
            ),
            CustomButton(
              text: "With Icon",
              onPressed: () {},
              type: ButtonType.primary,
              size: ButtonSize.small,
              icon: Icons.star,
            ),
            CustomButton(
              text: "Loading",
              onPressed: () {},
              type: ButtonType.primary,
              size: ButtonSize.small,
              isLoading: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Items List",
          icon: Icons.list,
          badge: "${_items.length}",
        ),
        ResponsiveSpacing(size: 12),
        if (_items.isEmpty)
          EmptyState(
            icon: Icons.inbox,
            title: "No items yet",
            message: "Tap the + button to add your first item",
            actionText: "Add Item",
            onActionPressed: () {
              setState(() {
                _items.add('Item ${_items.length + 1}');
              });
            },
          )
        else
          ...List.generate(
            _items.length,
            (index) => CustomCard(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on ${_items[index]}')),
                );
              },
              margin: ResponsiveUtils.padding(context, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: ResponsiveUtils.spacing(context, 50),
                    height: ResponsiveUtils.spacing(context, 50),
                    decoration: BoxDecoration(
                      color: primaryColor100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: primaryColor500,
                      size: ResponsiveUtils.spacing(context, 24),
                    ),
                  ),
                  ResponsiveSpacing(size: 16, axis: Axis.horizontal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _items[index],
                          style: subTitleTextStyle.copyWith(
                            fontSize: ResponsiveUtils.fontSize(context, 14),
                          ),
                        ),
                        ResponsiveSpacing(size: 4),
                        Text(
                          "Item description goes here",
                          style: descTextStyle.copyWith(
                            fontSize: ResponsiveUtils.fontSize(context, 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _items.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
