subroutine mld_z_base_solver_apply(alpha,sv,x,beta,y,desc_data,trans,work,info)
  
  use psb_base_mod
  use mld_z_base_solver_mod, mld_protect_name =>  mld_z_base_solver_apply
  implicit none 
  type(psb_desc_type), intent(in)           :: desc_data
  class(mld_z_base_solver_type), intent(in) :: sv
  complex(psb_dpk_),intent(inout)              :: x(:)
  complex(psb_dpk_),intent(inout)              :: y(:)
  complex(psb_dpk_),intent(in)                 :: alpha,beta
  character(len=1),intent(in)               :: trans
  complex(psb_dpk_),target, intent(inout)      :: work(:)
  integer, intent(out)                      :: info

  Integer :: err_act
  character(len=20)  :: name='d_base_solver_apply'

  call psb_erractionsave(err_act)

  info = psb_err_missing_override_method_
  call psb_errpush(info,name)
  goto 9999 

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == psb_act_abort_) then
    call psb_error()
    return
  end if
  return

end subroutine mld_z_base_solver_apply
