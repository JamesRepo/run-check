import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:run_check/providers/location_provider.dart';

class LocationBottomSheet extends ConsumerStatefulWidget {
  const LocationBottomSheet({super.key});

  @override
  ConsumerState<LocationBottomSheet> createState() =>
      _LocationBottomSheetState();
}

class _LocationBottomSheetState extends ConsumerState<LocationBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  _LocationAction? _lastAction;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationState = ref.watch(locationProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isLoading = locationState.isLoading;
    final errorMessage = locationState.errorMessage;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Set your location', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isLoading ? null : _useCurrentLocation,
              icon: isLoading && _lastAction == _LocationAction.current
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_outlined),
              label: const Text('Use my current location'),
            ),
            if (_lastAction == _LocationAction.current && errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  labelText: 'Search city',
                  prefixIcon: Icon(Icons.search),
                ),
                onFieldSubmitted: (_) => _searchForLocation(),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a city name';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: isLoading ? null : _searchForLocation,
              child: isLoading && _lastAction == _LocationAction.search
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Search'),
            ),
            if (_lastAction == _LocationAction.search && errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  errorMessage,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _lastAction = _LocationAction.current;
    });

    await ref.read(locationProvider.notifier).detectCurrentLocation();
    _closeOnSuccess();
  }

  Future<void> _searchForLocation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _lastAction = _LocationAction.search;
    });

    await ref
        .read(locationProvider.notifier)
        .searchLocation(_searchController.text.trim());
    _closeOnSuccess();
  }

  void _closeOnSuccess() {
    final locationState = ref.read(locationProvider);
    if (locationState.errorMessage == null && mounted) {
      Navigator.of(context).pop();
    }
  }
}

enum _LocationAction { current, search }
