!!$
!!$ 
!!$                           MLD2P4  version 2.0
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS version 3.0)
!!$  
!!$  (C) Copyright 2008,2009,2010,2012
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
!
!
!
!
subroutine mld_d_jac_smoother_apply_vect(alpha,sm,x,beta,y,desc_data,trans,sweeps,work,info)
  use psb_base_mod
  use mld_d_jac_smoother, mld_protect_name => mld_d_jac_smoother_apply_vect
  implicit none 
  type(psb_desc_type), intent(in)               :: desc_data
  class(mld_d_jac_smoother_type), intent(inout) :: sm
  type(psb_d_vect_type),intent(inout)           :: x
  type(psb_d_vect_type),intent(inout)           :: y
  real(psb_dpk_),intent(in)                     :: alpha,beta
  character(len=1),intent(in)                   :: trans
  integer, intent(in)                           :: sweeps
  real(psb_dpk_),target, intent(inout)          :: work(:)
  integer, intent(out)                          :: info

  integer    :: n_row,n_col
  type(psb_d_vect_type)  :: tx, ty
  real(psb_dpk_), pointer :: ww(:), aux(:)
  integer    :: ictxt,np,me,i, err_act
  character          :: trans_
  character(len=20)  :: name='d_jac_smoother_apply'

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

  if (.not.allocated(sm%sv)) then 
    info = 1121
    call psb_errpush(info,name)
    goto 9999
  end if

  n_row = desc_data%get_local_rows()
  n_col = desc_data%get_local_cols()

  if (n_col <= size(work)) then 
    ww => work(1:n_col)
    if ((4*n_col+n_col) <= size(work)) then 
      aux => work(n_col+1:)
    else
      allocate(aux(4*n_col),stat=info)
      if (info /= psb_success_) then 
        info=psb_err_alloc_request_
        call psb_errpush(info,name,i_err=(/4*n_col,0,0,0,0/),&
             & a_err='real(psb_dpk_)')
        goto 9999      
      end if
    endif
  else
    allocate(ww(n_col),aux(4*n_col),stat=info)
    if (info /= psb_success_) then 
      info=psb_err_alloc_request_
      call psb_errpush(info,name,i_err=(/5*n_col,0,0,0,0/),&
           & a_err='real(psb_dpk_)')
      goto 9999      
    end if
  endif

  if ((sweeps == 1).or.(sm%nnz_nd_tot==0)) then 

    call sm%sv%apply(alpha,x,beta,y,desc_data,trans_,aux,info) 

    if (info /= psb_success_) then
      call psb_errpush(psb_err_internal_error_,&
           & name,a_err='Error in sub_aply Jacobi Sweeps = 1')
      goto 9999
    endif

  else if (sweeps  > 1) then 

    !
    !
    ! Apply multiple sweeps of a block-Jacobi solver
    ! to compute an approximate solution of a linear system.
    !
    !
    call tx%bld(x%get_nrows(),mold=x%v)
    call tx%set(dzero)
    call ty%bld(x%get_nrows(),mold=x%v)

    do i=1, sweeps
      !
      ! Compute Y(j+1) = D^(-1)*(X-ND*Y(j)), where D and ND are the
      ! block diagonal part and the remaining part of the local matrix
      ! and Y(j) is the approximate solution at sweep j.
      !
      call psb_geaxpby(done,x,dzero,ty,desc_data,info)
      call psb_spmm(-done,sm%nd,tx,done,ty,desc_data,info,work=aux,trans=trans_)

      if (info /= psb_success_) exit

      call sm%sv%apply(done,ty,dzero,tx,desc_data,trans_,aux,info) 

      if (info /= psb_success_) exit
    end do

    if (info == psb_success_) call psb_geaxpby(alpha,tx,beta,y,desc_data,info)

    if (info /= psb_success_) then 
      info=psb_err_internal_error_
      call psb_errpush(info,name,a_err='subsolve with Jacobi sweeps > 1')
      goto 9999      
    end if

    call tx%free(info) 
    if (info == psb_success_) call ty%free(info) 
    if (info /= psb_success_) then 
      info=psb_err_internal_error_
      call psb_errpush(info,name,a_err='final cleanup with Jacobi sweeps > 1')
      goto 9999      
    end if

  else

    info = psb_err_iarg_neg_
    call psb_errpush(info,name,&
         & i_err=(/2,sweeps,0,0,0/))
    goto 9999

  endif


  if (n_col <= size(work)) then 
    if ((4*n_col+n_col) <= size(work)) then 
    else
      deallocate(aux)
    endif
  else
    deallocate(ww,aux)
  endif

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == psb_act_abort_) then
    call psb_error()
    return
  end if
  return

end subroutine mld_d_jac_smoother_apply_vect

subroutine mld_d_jac_smoother_apply(alpha,sm,x,beta,y,desc_data,trans,sweeps,work,info)
  use psb_base_mod
  use mld_d_jac_smoother, mld_protect_name => mld_d_jac_smoother_apply
  implicit none 
  type(psb_desc_type), intent(in)      :: desc_data
  class(mld_d_jac_smoother_type), intent(in) :: sm
  real(psb_dpk_),intent(inout)         :: x(:)
  real(psb_dpk_),intent(inout)         :: y(:)
  real(psb_dpk_),intent(in)            :: alpha,beta
  character(len=1),intent(in)          :: trans
  integer, intent(in)                  :: sweeps
  real(psb_dpk_),target, intent(inout) :: work(:)
  integer, intent(out)                 :: info

  integer    :: n_row,n_col
  real(psb_dpk_), pointer :: ww(:), aux(:), tx(:),ty(:)
  integer    :: ictxt,np,me,i, err_act
  character          :: trans_
  character(len=20)  :: name='d_jac_smoother_apply'

  call psb_erractionsave(err_act)

  info = psb_success_

  trans_ = psb_toupper(trans)
  select case(trans_)
  case('N')
  case('T','C')
  case default
    call psb_errpush(psb_err_iarg_invalid_i_,name)
    goto 9999
  end select

  if (.not.allocated(sm%sv)) then 
    info = 1121
    call psb_errpush(info,name)
    goto 9999
  end if

  n_row = desc_data%get_local_rows()
  n_col = desc_data%get_local_cols()

  if (n_col <= size(work)) then 
    ww => work(1:n_col)
    if ((4*n_col+n_col) <= size(work)) then 
      aux => work(n_col+1:)
    else
      allocate(aux(4*n_col),stat=info)
      if (info /= psb_success_) then 
        info=psb_err_alloc_request_
        call psb_errpush(info,name,i_err=(/4*n_col,0,0,0,0/),&
             & a_err='real(psb_dpk_)')
        goto 9999      
      end if
    endif
  else
    allocate(ww(n_col),aux(4*n_col),stat=info)
    if (info /= psb_success_) then 
      info=psb_err_alloc_request_
      call psb_errpush(info,name,i_err=(/5*n_col,0,0,0,0/),&
           & a_err='real(psb_dpk_)')
      goto 9999      
    end if
  endif

  if ((sweeps == 1).or.(sm%nnz_nd_tot==0)) then 

    call sm%sv%apply(alpha,x,beta,y,desc_data,trans_,aux,info) 

    if (info /= psb_success_) then
      call psb_errpush(psb_err_internal_error_,&
           & name,a_err='Error in sub_aply Jacobi Sweeps = 1')
      goto 9999
    endif

  else if (sweeps  > 1) then 

    !
    !
    ! Apply multiple sweeps of a block-Jacobi solver
    ! to compute an approximate solution of a linear system.
    !
    !
    allocate(tx(n_col),ty(n_col),stat=info)
    if (info /= psb_success_) then 
      info=psb_err_alloc_request_
      call psb_errpush(info,name,i_err=(/2*n_col,0,0,0,0/),&
           & a_err='real(psb_dpk_)')
      goto 9999      
    end if

    tx = dzero
    ty = dzero
    do i=1, sweeps
      !
      ! Compute Y(j+1) = D^(-1)*(X-ND*Y(j)), where D and ND are the
      ! block diagonal part and the remaining part of the local matrix
      ! and Y(j) is the approximate solution at sweep j.
      !
      ty(1:n_row) = x(1:n_row)
      call psb_spmm(-done,sm%nd,tx,done,ty,desc_data,info,work=aux,trans=trans_)

      if (info /= psb_success_) exit

      call sm%sv%apply(done,ty,dzero,tx,desc_data,trans_,aux,info) 

      if (info /= psb_success_) exit
    end do

    if (info == psb_success_) call psb_geaxpby(alpha,tx,beta,y,desc_data,info)

    if (info /= psb_success_) then 
      info=psb_err_internal_error_
      call psb_errpush(info,name,a_err='subsolve with Jacobi sweeps > 1')
      goto 9999      
    end if

    deallocate(tx,ty,stat=info)
    if (info /= psb_success_) then 
      info=psb_err_internal_error_
      call psb_errpush(info,name,a_err='final cleanup with Jacobi sweeps > 1')
      goto 9999      
    end if

  else

    info = psb_err_iarg_neg_
    call psb_errpush(info,name,&
         & i_err=(/2,sweeps,0,0,0/))
    goto 9999

  endif


  if (n_col <= size(work)) then 
    if ((4*n_col+n_col) <= size(work)) then 
    else
      deallocate(aux)
    endif
  else
    deallocate(ww,aux)
  endif

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == psb_act_abort_) then
    call psb_error()
    return
  end if
  return

end subroutine mld_d_jac_smoother_apply

subroutine mld_d_jac_smoother_bld(a,desc_a,sm,upd,info,amold,vmold)

  use psb_base_mod
  use mld_d_diag_solver
  use mld_d_jac_smoother, mld_protect_name => mld_d_jac_smoother_bld
  Implicit None

  ! Arguments
  type(psb_dspmat_type), intent(in), target          :: a
  Type(psb_desc_type), Intent(in)                    :: desc_a 
  class(mld_d_jac_smoother_type), intent(inout)      :: sm
  character, intent(in)                              :: upd
  integer, intent(out)                               :: info
  class(psb_d_base_sparse_mat), intent(in), optional :: amold
  class(psb_d_base_vect_type), intent(in), optional  :: vmold
  ! Local variables
  integer :: n_row,n_col, nrow_a, nztota, nzeros
  real(psb_dpk_), pointer :: ww(:), aux(:), tx(:),ty(:)
  integer :: ictxt,np,me,i, err_act, debug_unit, debug_level
  character(len=20)  :: name='d_jac_smoother_bld', ch_err

  info=psb_success_
  call psb_erractionsave(err_act)
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()
  ictxt       = desc_a%get_context()
  call psb_info(ictxt, me, np)
  if (debug_level >= psb_debug_outer_) &
       & write(debug_unit,*) me,' ',trim(name),' start'


  n_row  = desc_a%get_local_rows()

  nrow_a = a%get_nrows()
  nztota = a%get_nzeros()
  select type (smsv => sm%sv)
  type is (mld_d_diag_solver_type)
    call a%clip_diag(sm%nd,info)
    class default
    call a%csclip(sm%nd,info,&
         & jmin=nrow_a+1,rscale=.false.,cscale=.false.)
  end select
  if (info == psb_success_) then 
    if (present(amold)) then 
      call sm%nd%cscnv(info,&
           & mold=amold,dupl=psb_dupl_add_)
    else
      call sm%nd%cscnv(info,&
           & type='csr',dupl=psb_dupl_add_)
    endif
  end if
  if (info /= psb_success_) then
    call psb_errpush(psb_err_from_subroutine_,name,&
         & a_err='clip & psb_spcnv csr 4')
    goto 9999
  end if

  call sm%sv%build(a,desc_a,upd,info,amold=amold,vmold=vmold)
  if (info /= psb_success_) then
    call psb_errpush(psb_err_from_subroutine_,name,&
         & a_err='solver build')
    goto 9999
  end if
  nzeros = sm%nd%get_nzeros()
  call psb_sum(ictxt,nzeros)
  sm%nnz_nd_tot = nzeros
  if (debug_level >= psb_debug_outer_) &
       & write(debug_unit,*) me,' ',trim(name),' end'

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == psb_act_abort_) then
    call psb_error()
    return
  end if
  return

end subroutine mld_d_jac_smoother_bld
