  subroutine mld_z_id_solver_apply(alpha,sv,x,beta,y,desc_data,trans,work,info)
    
    use psb_base_mod
    use mld_z_id_solver, mld_protect_name => mld_z_id_solver_apply
    implicit none 
    type(psb_desc_type), intent(in)      :: desc_data
    class(mld_z_id_solver_type), intent(in) :: sv
    complex(psb_dpk_),intent(inout)         :: x(:)
    complex(psb_dpk_),intent(inout)         :: y(:)
    complex(psb_dpk_),intent(in)            :: alpha,beta
    character(len=1),intent(in)          :: trans
    complex(psb_dpk_),target, intent(inout) :: work(:)
    integer, intent(out)                 :: info

    integer    :: n_row,n_col
    integer    :: ictxt,np,me,i, err_act
    character          :: trans_
    character(len=20)  :: name='z_id_solver_apply'

    call psb_erractionsave(err_act)

    info = psb_success_

    trans_ = psb_toupper(trans)
    select case(trans_)
    case('N')
    case('T')
    case('C')
    case default
      call psb_errpush(psb_err_iarg_invalid_i_,name)
      goto 9999
    end select

    call psb_geaxpby(alpha,x,beta,y,desc_data,info)    

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return

  end subroutine mld_z_id_solver_apply
