import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/hospital_repository.dart';
import 'state_views.dart';

/// Runs an asynchronous repository query and re-runs it whenever the
/// repository reports a change.
///
/// A plain [FutureBuilder] would fetch once and then show stale data after a
/// write; listening to the repository as well means a screen refreshes itself
/// when another part of the application admits a patient or dispenses a dose,
/// with no manual invalidation to forget.
class RepositoryBuilder<T> extends StatefulWidget {
  const RepositoryBuilder({
    super.key,
    required this.query,
    required this.builder,
    this.loading,
    this.keepPreviousWhileLoading = true,
  });

  /// The read to perform. Called again on every repository change.
  final Future<T> Function(HospitalRepository repository) query;

  final Widget Function(BuildContext context, T data) builder;

  /// Shown on the very first load. Later refreshes reuse the previous data.
  final Widget? loading;

  /// Keeps the last successful result on screen while a refresh is in flight,
  /// so a list does not flash empty every time something is saved.
  final bool keepPreviousWhileLoading;

  @override
  State<RepositoryBuilder<T>> createState() => _RepositoryBuilderState<T>();
}

class _RepositoryBuilderState<T> extends State<RepositoryBuilder<T>> {
  HospitalRepository? _repository;
  T? _data;
  Object? _error;
  bool _loading = true;

  /// Guards against an earlier, slower query overwriting a later one.
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = context.read<HospitalRepository>();
    if (identical(repository, _repository)) return;
    _repository?.removeListener(_run);
    _repository = repository..addListener(_run);
    _run();
  }

  @override
  void didUpdateWidget(RepositoryBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The query closure usually captures search text or a filter, so a rebuild
    // of the parent has to re-run it.
    _run();
  }

  @override
  void dispose() {
    _repository?.removeListener(_run);
    super.dispose();
  }

  Future<void> _run() async {
    final repository = _repository;
    if (repository == null) return;
    final generation = ++_generation;
    if (!widget.keepPreviousWhileLoading || _data == null) {
      if (mounted) setState(() => _loading = true);
    }
    try {
      final result = await widget.query(repository);
      if (!mounted || generation != _generation) return;
      setState(() {
        _data = result;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorView(error: _error!, onRetry: _run);
    }
    final data = _data;
    if (data == null) {
      return _loading ? (widget.loading ?? const LoadingView()) : const SizedBox.shrink();
    }
    return widget.builder(context, data);
  }
}
