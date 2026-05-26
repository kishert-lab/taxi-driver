class Loadable<T> {
  const Loadable({required this.isLoading, this.value, this.errorMessage});

  const Loadable.idle([T? value]) : this(isLoading: false, value: value);

  const Loadable.loading([T? value]) : this(isLoading: true, value: value);

  final bool isLoading;
  final T? value;
  final String? errorMessage;

  Loadable<T> copyWith({bool? isLoading, T? value, String? errorMessage}) {
    return Loadable<T>(
      isLoading: isLoading ?? this.isLoading,
      value: value ?? this.value,
      errorMessage: errorMessage,
    );
  }
}
