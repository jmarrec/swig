/* Test SWIG's handling of C++20 concepts.
 *
 * Summary of findings (SWIG 4.2.0):
 *   OK  - concept definitions (simple constraint or requires expression)
 *   OK  - template<ConceptName T> constrained template parameters
 *   FAIL - trailing requires clause: `T f(T x) requires Concept<T>`
 *   FAIL - abbreviated function templates: `Concept auto f(Concept auto x)`
 *   FAIL - requires clause on member functions: `T get() const requires Concept<T>`
 *
 * Workaround: guard failing constructs with #if INCLUDE_FAILING.
 */
%module cpp20_concepts

%inline %{
#include <concepts>
#include <iostream>

#define INCLUDE_FAILING 1

// --- Constructs SWIG parses without error ---

// Basic concept definition: OK
template<typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

// Concept with requires expression: OK
template<typename T>
concept Addable = requires(T a, T b) {
  { a + b } -> std::same_as<T>;
};

template<typename T>
concept AddableInteger = Numeric<T> && std::integral<T>;

template <typename T>
concept UniqueAddable = Addable<T> && requires {
  { T::is_unique } -> std::convertible_to<bool>;
  requires T::is_unique;
};


// Constrained template parameter (concept-name as type): OK (wraps the template)
template<Numeric T>
T constrained_template_parameter(T x) {
  return x * x;
}
// --- Constructs that cause SWIG parse errors ---

// Trailing requires clause on a free function: FAIL
template<typename T>
T trailing_requires_clause_free_function(T x)
#if INCLUDE_FAILING
  requires Numeric<T>
#endif
{
  return x * x * x;
}

// Abbreviated function template (C++20): FAIL
#if INCLUDE_FAILING
Numeric auto abbreviated_function_template(Numeric auto x) { return x + x; }
auto abbreviated_function_template_auto_only(auto x) { return x + x; }
#endif

// Requires clause on a class member function: FAIL
template<typename T>
struct RequireClauseOnClassMemberFunction {
  T value;
  T get() const
#if INCLUDE_FAILING
    requires Numeric<T>
#endif
  {
    return value; }
  };


// Function constrained by concept: should resolve by most specific (Integral) to less specific concept (Numeric)
template<typename T>
concept Integral = std::integral<T>;

#if INCLUDE_FAILING
template <Integral T>
void function_resolve() {
  std::cout << "Integral\n";
}

template <Numeric T>
void function_resolve() {
  std::cout << "Numeric\n";
}
#endif

template<Numeric T>
void function_resolve_via_constexpr() {
  if constexpr (std::integral<T>) {
    std::cout << "Integral\n";
  } else {
    std::cout << "Numeric\n";
  }
}

%}
