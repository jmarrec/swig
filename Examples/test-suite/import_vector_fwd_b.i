/* See import_vector_fwd_a.i for the full explanation of this regression test.

   This module %imports import_vector_fwd_a.i (which only forward-declares Bar) and
   supplies the real definition of Bar, plus %template(BarVector) std::vector<Bar>. */
%module import_vector_fwd_b

%import "import_vector_fwd_a.i"

%{
#include "import_vector_fwd.h"
%}

%include <std_vector.i>

class Bar {
public:
  Bar();
  Bar(std::string name);
  std::string name() const;
};

%template(BarVector) std::vector<Bar>;
