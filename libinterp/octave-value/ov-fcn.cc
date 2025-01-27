////////////////////////////////////////////////////////////////////////
//
// Copyright (C) 1996-2024 The Octave Project Developers
//
// See the file COPYRIGHT.md in the top-level directory of this
// distribution or <https://octave.org/copyright/>.
//
// This file is part of Octave.
//
// Octave is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Octave is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Octave; see the file COPYING.  If not, see
// <https://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////

#if defined (HAVE_CONFIG_H)
#  include "config.h"
#endif

#include "lo-array-errwarn.h"
#include "unwind-prot.h"

#include "error.h"
#include "filepos.h"
#include "interpreter-private.h"
#include "interpreter.h"
#include "ov-fcn.h"
#include "ovl.h"
#include "pt-eval.h"
#include "symtab.h"

octave_base_value *
octave_function::clone () const
{
  error ("unexpected call to octave_function::clone - please report this bug");
}

octave_base_value *
octave_function::empty_clone () const
{
  error ("unexpected call to octave_function::empty_clone - please report this bug");
}

octave::filepos
octave_function::beg_pos () const
{
  error ("unexpected call to octave_function::beg_pos - please report this bug");
}

octave::filepos
octave_function::end_pos () const
{
  error ("unexpected call to octave_function::end_pos - please report this bug");
}

octave_value_list
octave_function::call (octave::tree_evaluator& tw, int nargout,
                       const octave_value_list& args)
{
  tw.push_stack_frame (this);

  octave::unwind_action act ([&tw] () { tw.pop_stack_frame (); });

  return execute (tw, nargout, args);
}
