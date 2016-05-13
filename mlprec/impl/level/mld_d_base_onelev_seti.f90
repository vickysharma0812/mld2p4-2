!!$
!!$ 
!!$                           MLD2P4  version 2.0
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS version 3.3)
!!$  
!!$  (C) Copyright 2008, 2010, 2012, 2015
!!$
!!$                      Salvatore Filippone  University of Rome Tor Vergata
!!$                      Alfredo Buttari      CNRS-IRIT, Toulouse
!!$                      Pasqua D'Ambra       ICAR-CNR, Naples
!!$                      Daniela di Serafino  Second University of Naples
!!$ 
!!$  Redistribution and use in source and binary forms, with or without
!!$  modification, are permitted provided that the following conditions
!!$  are met:
!!$    1. Redistributions of source code must retain the above copyright
!!$       notice, this list of conditions and the following disclaimer.
!!$    2. Redistributions in binary form must reproduce the above copyright
!!$       notice, this list of conditions, and the following disclaimer in the
!!$       documentation and/or other materials provided with the distribution.
!!$    3. The name of the MLD2P4 group or the names of its contributors may
!!$       not be used to endorse or promote products derived from this
!!$       software without specific written permission.
!!$ 
!!$  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!!$  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!!$  TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!!$  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MLD2P4 GROUP OR ITS CONTRIBUTORS
!!$  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!!$  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!!$  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!!$  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!!$  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!!$  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!!$  POSSIBILITY OF SUCH DAMAGE.
!!$ 
!!$
subroutine mld_d_base_onelev_seti(lv,what,val,info,pos)
  
  use psb_base_mod
  use mld_d_onelev_mod, mld_protect_name => mld_d_base_onelev_seti

  Implicit None

  ! Arguments
  class(mld_d_onelev_type), intent(inout) :: lv 
  integer(psb_ipk_), intent(in)             :: what 
  integer(psb_ipk_), intent(in)             :: val
  integer(psb_ipk_), intent(out)            :: info
  character(len=*), optional, intent(in)      :: pos
  ! Local 
  integer(psb_ipk_)  :: ipos_, err_act
  character(len=20) :: name='d_base_onelev_seti'

  call psb_erractionsave(err_act)
  info = psb_success_

  select case (what) 

  case (mld_smoother_sweeps_)
    lv%parms%sweeps      = val
    lv%parms%sweeps_pre  = val
    lv%parms%sweeps_post = val

  case (mld_smoother_sweeps_pre_)
    lv%parms%sweeps_pre  = val

  case (mld_smoother_sweeps_post_)
    lv%parms%sweeps_post = val

  case (mld_ml_type_)
    lv%parms%ml_type       = val

  case (mld_aggr_alg_)
    lv%parms%aggr_alg      = val

  case (mld_aggr_ord_)
    lv%parms%aggr_ord      = val

  case (mld_aggr_kind_)
    lv%parms%aggr_kind     = val

  case (mld_coarse_mat_)
    lv%parms%coarse_mat    = val

  case (mld_smoother_pos_)
    lv%parms%smoother_pos  = val

  case (mld_aggr_omega_alg_)
    lv%parms%aggr_omega_alg= val

  case (mld_aggr_eig_)
    lv%parms%aggr_eig      = val

  case (mld_aggr_filter_)
    lv%parms%aggr_filter   = val

  case (mld_coarse_solve_)
    lv%parms%coarse_solve    = val

  case default
    
    if (present(pos)) then
      select case(psb_toupper(trim(pos)))
      case('PRE')
        ipos_ = mld_pre_smooth_
      case('POST')
        ipos_ = mld_post_smooth_
      case default
        ipos_ = mld_pre_smooth_
      end select
    else
      ipos_ = mld_pre_smooth_
    end if
    select case(ipos_)
    case(mld_pre_smooth_) 
      if (allocated(lv%sm)) then 
        call lv%sm%set(what,val,info)
      end if
    case (mld_post_smooth_)
      if (allocated(lv%sm2a)) then 
        call lv%sm2a%set(what,val,info)
      end if
    case default
      ! Impossible!! 
      info = psb_err_internal_error_
    end select

  end select
  if (info /= psb_success_) goto 9999
  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)
  return

end subroutine mld_d_base_onelev_seti
