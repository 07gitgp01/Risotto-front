import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../application/connections_providers.dart';
import 'widgets/connection_button.dart';
import 'widgets/member_tile.dart';
import '../../../core/widgets/risotto_ui.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(memberSearchProvider(_query));
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              onSubmitted: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                labelText: 'Nom, titre ou entreprise',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: _query.length < 2
                ? const _Hint('Saisissez au moins 2 caractères.')
                : results.when(
                    loading: () => const PageLoading(),
                    error: (error, _) => _Hint(
                      error is ApiException
                          ? error.message
                          : 'La recherche a échoué.',
                    ),
                    data: (profiles) => profiles.isEmpty
                        ? const _Hint('Aucun membre trouvé.')
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                            itemCount: profiles.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final profile = profiles[index];
                              return SurfaceCard(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: MemberTile(
                                  profile: profile,
                                  below: profile.connection == null
                                      ? null
                                      : Align(
                                          alignment: Alignment.centerLeft,
                                          child: ConnectionButton(
                                            userId: profile.userId,
                                            name: profile.firstName,
                                            state: profile.connection!,
                                            compact: true,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
