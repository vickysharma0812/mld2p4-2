!  
!   
!                             MLD2P4  version 2.2
!    MultiLevel Domain Decomposition Parallel Preconditioners Package
!               based on PSBLAS (Parallel Sparse BLAS version 3.5)
!    
!    (C) Copyright 2008-2018 
!  
!        Salvatore Filippone  
!        Pasqua D'Ambra   
!        Daniela di Serafino   
!   
!    Redistribution and use in source and binary forms, with or without
!    modification, are permitted provided that the following conditions
!    are met:
!      1. Redistributions of source code must retain the above copyright
!         notice, this list of conditions and the following disclaimer.
!      2. Redistributions in binary form must reproduce the above copyright
!         notice, this list of conditions, and the following disclaimer in the
!         documentation and/or other materials provided with the distribution.
!      3. The name of the MLD2P4 group or the names of its contributors may
!         not be used to endorse or promote products derived from this
!         software without specific written permission.
!   
!    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!    ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
!    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
!    PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE MLD2P4 GROUP OR ITS CONTRIBUTORS
!    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
!    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
!    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
!    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
!    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
!    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
!    POSSIBILITY OF SUCH DAMAGE.
!   
!  
!
! File: mld_d_umf_solver_mod.f90
!
! Module: mld_d_umf_solver_mod
!
!  This module defines: 
!  - the mld_d_umf_solver_type data structure containing the ingredients
!    to interface with the UMFPACK package. 
!    1. The factorization is restricted to the diagonal block of the
!       current image.
!
module mld_d_umf_solver

  use iso_c_binding
  use mld_d_base_solver_mod

#if defined(IPK8)
  type, extends(mld_d_base_solver_type) :: mld_d_umf_solver_type

  end type mld_d_umf_solver_type

#else
  
  type, extends(mld_d_base_solver_type) :: mld_d_umf_solver_type
    type(c_ptr)                 :: symbolic=c_null_ptr, numeric=c_null_ptr
    integer(c_long_long)        :: symbsize=0, numsize=0
  contains
    procedure, pass(sv) :: build   => d_umf_solver_bld
    procedure, pass(sv) :: apply_a => d_umf_solver_apply
    procedure, pass(sv) :: apply_v => d_umf_solver_apply_vect
    procedure, pass(sv) :: free    => d_umf_solver_free
    procedure, pass(sv) :: descr   => d_umf_solver_descr
    procedure, pass(sv) :: sizeof  => d_umf_solver_sizeof
    procedure, nopass   :: get_fmt => d_umf_solver_get_fmt
    procedure, nopass   :: get_id  => d_umf_solver_get_id
#if defined(HAVE_FINAL) 
    final               :: d_umf_solver_finalize
#endif
  end type mld_d_umf_solver_type


  private :: d_umf_solver_bld, d_umf_solver_apply, &
       &  d_umf_solver_free,   d_umf_solver_descr, &
       &  d_umf_solver_sizeof, d_umf_solver_apply_vect, &
       &  d_umf_solver_get_fmt, d_umf_solver_get_id
#if defined(HAVE_FINAL) 
  private :: d_umf_solver_finalize
#endif



  interface 
    function mld_dumf_fact(n,nnz,values,rowind,colptr,&
         & symptr,numptr,ssize,nsize)&
         & bind(c,name='mld_dumf_fact') result(info)
      use iso_c_binding
      integer(c_int), value :: n,nnz
      integer(c_int)        :: info
      integer(c_long_long)  :: ssize, nsize
      integer(c_int)        :: rowind(*),colptr(*)
      real(c_double)  :: values(*)
      type(c_ptr)           :: symptr, numptr
    end function mld_dumf_fact
  end interface

  interface 
    function mld_dumf_solve(itrans,n,x, b, ldb, numptr)&
         & bind(c,name='mld_dumf_solve') result(info)
      use iso_c_binding
      integer(c_int)        :: info
      integer(c_int), value :: itrans,n,ldb
      real(c_double) :: x(*), b(ldb,*)
      type(c_ptr), value    :: numptr
    end function mld_dumf_solve
  end interface

  interface 
    function mld_dumf_free(symptr, numptr)&
         & bind(c,name='mld_dumf_free') result(info)
      use iso_c_binding
      integer(c_int)        :: info
      type(c_ptr), value    :: symptr, numptr
    end function mld_dumf_free
  end interface

contains

  subroutine d_umf_solver_apply(alpha,sv,x,beta,y,desc_data,&
       & trans,work,info,init,initu)
    use psb_base_mod
    implicit none 
    type(psb_desc_type), intent(in)      :: desc_data
    class(mld_d_umf_solver_type), intent(inout) :: sv
    real(psb_dpk_),intent(inout)         :: x(:)
    real(psb_dpk_),intent(inout)         :: y(:)
    real(psb_dpk_),intent(in)            :: alpha,beta
    character(len=1),intent(in)          :: trans
    real(psb_dpk_),target, intent(inout) :: work(:)
    integer, intent(out)                 :: info
    character, intent(in), optional       :: init
    real(psb_dpk_),intent(inout), optional :: initu(:)

    integer    :: n_row,n_col
    real(psb_dpk_), pointer :: ww(:)
    integer    :: ictxt,np,me,i, err_act
    character          :: trans_
    character(len=20)  :: name='d_umf_solver_apply'

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
    !
    ! For non-iterative solvers, init and initu are ignored.
    !

    n_row = desc_data%get_local_rows()
    n_col = desc_data%get_local_cols()

    if (n_col <= size(work)) then 
      ww => work(1:n_col)
    else
      allocate(ww(n_col),stat=info)
      if (info /= psb_success_) then 
        info=psb_err_alloc_request_
        call psb_errpush(info,name,i_err=(/n_col,0,0,0,0/),&
             & a_err='real(psb_dpk_)')
        goto 9999      
      end if
    endif

    select case(trans_)
    case('N')
      info = mld_dumf_solve(0,n_row,ww,x,n_row,sv%numeric)
    case('T')
      ! 
      ! Note: with UMF, 1 meand Ctranspose, 2 means transpose
      ! even for complex data. 
      !
      if (psb_d_is_complex_) then 
        info = mld_dumf_solve(2,n_row,ww,x,n_row,sv%numeric)
      else
        info = mld_dumf_solve(1,n_row,ww,x,n_row,sv%numeric)
      end if
    case('C')
      info = mld_dumf_solve(1,n_row,ww,x,n_row,sv%numeric)
    case default
      call psb_errpush(psb_err_internal_error_,name,a_err='Invalid TRANS in ILU subsolve')
      goto 9999
    end select

    if (info == psb_success_) call psb_geaxpby(alpha,ww,beta,y,desc_data,info)


    if (info /= psb_success_) then
      call psb_errpush(psb_err_internal_error_,name,a_err='Error in subsolve')
      goto 9999
    endif

    if (n_col > size(work)) then 
      deallocate(ww)
    endif

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return

  end subroutine d_umf_solver_apply

  subroutine d_umf_solver_apply_vect(alpha,sv,x,beta,y,desc_data,&
       & trans,work,wv,info,init,initu)
    use psb_base_mod
    implicit none 
    type(psb_desc_type), intent(in)      :: desc_data
    class(mld_d_umf_solver_type), intent(inout) :: sv
    type(psb_d_vect_type),intent(inout)  :: x
    type(psb_d_vect_type),intent(inout)  :: y
    real(psb_dpk_),intent(in)            :: alpha,beta
    character(len=1),intent(in)           :: trans
    real(psb_dpk_),target, intent(inout) :: work(:)
    type(psb_d_vect_type),intent(inout) :: wv(:)
    integer, intent(out)                 :: info
    character, intent(in), optional                :: init
    type(psb_d_vect_type),intent(inout), optional   :: initu

    integer    :: err_act
    character(len=20)  :: name='d_umf_solver_apply_vect'

    call psb_erractionsave(err_act)

    info = psb_success_
    !
    ! For non-iterative solvers, init and initu are ignored.
    !

    call x%v%sync()
    call y%v%sync()
    call sv%apply(alpha,x%v%v,beta,y%v%v,desc_data,trans,work,info)
    call y%v%set_host()
    if (info /= 0) goto 9999

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return

  end subroutine d_umf_solver_apply_vect

  subroutine d_umf_solver_bld(a,desc_a,sv,info,b,amold,vmold,imold)

    use psb_base_mod

    Implicit None

    ! Arguments
    type(psb_dspmat_type), intent(in), target           :: a
    Type(psb_desc_type), Intent(in)                     :: desc_a 
    class(mld_d_umf_solver_type), intent(inout)         :: sv
    integer, intent(out)                                :: info
    type(psb_dspmat_type), intent(in), target, optional :: b
    class(psb_d_base_sparse_mat), intent(in), optional  :: amold
    class(psb_d_base_vect_type), intent(in), optional   :: vmold
    class(psb_i_base_vect_type), intent(in), optional  :: imold
    ! Local variables
    type(psb_dspmat_type) :: atmp
    type(psb_d_csc_sparse_mat) :: acsc
    integer :: n_row,n_col, nrow_a, nztota
    integer :: ictxt,np,me,i, err_act, debug_unit, debug_level
    character(len=20)  :: name='d_umf_solver_bld', ch_err
    
    info=psb_success_
    call psb_erractionsave(err_act)
    debug_unit  = psb_get_debug_unit()
    debug_level = psb_get_debug_level()
    ictxt       = desc_a%get_context()
    call psb_info(ictxt, me, np)
    if (debug_level >= psb_debug_outer_) &
         & write(debug_unit,*) me,' ',trim(name),' start'


    n_row  = desc_a%get_local_rows()
    n_col  = desc_a%get_local_cols()

    call a%cscnv(atmp,info,type='coo')
    call psb_rwextd(n_row,atmp,info,b=b) 
    call atmp%cscnv(info,type='csc',dupl=psb_dupl_add_)
    call atmp%mv_to(acsc)
    nrow_a = acsc%get_nrows()
    nztota = acsc%get_nzeros()
    ! Fix the entres to call C-base UMFPACK. 
    acsc%ia(:)  = acsc%ia(:) - 1
    acsc%icp(:) = acsc%icp(:) - 1
    info = mld_dumf_fact(nrow_a,nztota,acsc%val,&
         & acsc%ia,acsc%icp,sv%symbolic,sv%numeric,&
         & sv%symbsize,sv%numsize)
    
    if (info /= psb_success_) then
      info=psb_err_from_subroutine_
      ch_err='mld_dumf_fact'
      call psb_errpush(info,name,a_err=ch_err)
      goto 9999
    end if
    
    call acsc%free()
    call atmp%free()

    if (debug_level >= psb_debug_outer_) &
         & write(debug_unit,*) me,' ',trim(name),' end'

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_umf_solver_bld

  subroutine d_umf_solver_free(sv,info)

    Implicit None

    ! Arguments
    class(mld_d_umf_solver_type), intent(inout) :: sv
    integer, intent(out)                       :: info
    Integer :: err_act
    character(len=20)  :: name='d_umf_solver_free'

    call psb_erractionsave(err_act)

    
    info = mld_dumf_free(sv%symbolic,sv%numeric)
    
    if (info /= psb_success_) goto 9999
    sv%symbolic = c_null_ptr
    sv%numeric  = c_null_ptr
    sv%symbsize = 0
    sv%numsize  = 0

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_umf_solver_free

#if defined(HAVE_FINAL)
  subroutine d_umf_solver_finalize(sv)

    Implicit None

    ! Arguments
    type(mld_d_umf_solver_type), intent(inout) :: sv
    integer :: info
    Integer :: err_act
    character(len=20)  :: name='d_umf_solver_finalize'

    call sv%free(info) 

    return
  
  end subroutine d_umf_solver_finalize
#endif

  subroutine d_umf_solver_descr(sv,info,iout,coarse)

    Implicit None

    ! Arguments
    class(mld_d_umf_solver_type), intent(in) :: sv
    integer, intent(out)                     :: info
    integer, intent(in), optional            :: iout
    logical, intent(in), optional       :: coarse

    ! Local variables
    integer      :: err_act
    integer      :: ictxt, me, np
    character(len=20), parameter :: name='mld_d_umf_solver_descr'
    integer :: iout_

    call psb_erractionsave(err_act)
    info = psb_success_
    if (present(iout)) then 
      iout_ = iout 
    else
      iout_ = psb_out_unit
    endif
    
    write(iout_,*) '  UMFPACK Sparse Factorization Solver. '

    call psb_erractionrestore(err_act)
    return

9999 call psb_error_handler(err_act)
    return
  end subroutine d_umf_solver_descr

  function d_umf_solver_sizeof(sv) result(val)

    implicit none 
    ! Arguments
    class(mld_d_umf_solver_type), intent(in) :: sv
    integer(psb_epk_) :: val
    integer             :: i

    val = 2*psb_sizeof_lp 
    val = val + sv%symbsize
    val = val + sv%numsize
    return
  end function d_umf_solver_sizeof

  function d_umf_solver_get_fmt() result(val)
    implicit none 
    character(len=32)  :: val

    val = "UMFPACK solver"
  end function d_umf_solver_get_fmt

  function d_umf_solver_get_id() result(val)
    implicit none 
    integer(psb_ipk_)  :: val

    val = mld_umf_
  end function d_umf_solver_get_id
#endif
end module mld_d_umf_solver
