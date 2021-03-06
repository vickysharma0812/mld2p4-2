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
!  Current version of this file contributed by:
!        Ambra Abdullahi Hassan 
!
!
! File: mld_d_mumps_solver_mod.f90
!
! Module: mld_d_mumps_solver_mod
!
!  This module defines: 
!  - the mld_d_mumps_solver_type data structure containing the ingredients
!    to interface with the MUMPS package. 
!    1. The factorization can be either restricted to the diagonal block of the
!       current image or distributed (and thus exact)
!
module mld_d_mumps_solver
  use mld_d_base_solver_mod
#if defined(HAVE_MUMPS_) && defined(HAVE_MUMPS_MODULES_)
  use dmumps_struc_def
#endif
#if defined(HAVE_MUMPS_) && defined(HAVE_MUMPS_INCLUDES_)
  include 'dmumps_struc.h'
#endif  
  
#if defined(LPK8)
  
  type, extends(mld_d_base_solver_type) :: mld_d_mumps_solver_type
    
  end type mld_d_mumps_solver_type
#else
  
  type :: mld_d_mumps_icntl_item
    integer(psb_ipk_), allocatable :: item
  end type mld_d_mumps_icntl_item
  type :: mld_d_mumps_rcntl_item
    real(psb_dpk_), allocatable :: item
  end type mld_d_mumps_rcntl_item

  type, extends(mld_d_base_solver_type) :: mld_d_mumps_solver_type
#if defined(HAVE_MUMPS_)
    type(dmumps_struc), allocatable  :: id
#else
    integer, allocatable :: id
#endif
    type(mld_d_mumps_icntl_item), allocatable :: icntl(:)
    type(mld_d_mumps_rcntl_item), allocatable :: rcntl(:)
    integer(psb_ipk_), dimension(2) :: ipar
    integer(psb_ipk_), allocatable  :: local_ictxt
    logical                         :: built = .false.
  contains
    procedure, pass(sv) :: build   => d_mumps_solver_bld
    procedure, pass(sv) :: apply_a => d_mumps_solver_apply
    procedure, pass(sv) :: apply_v => d_mumps_solver_apply_vect
    procedure, pass(sv) :: free    => d_mumps_solver_free
    procedure, pass(sv) :: descr   => d_mumps_solver_descr
    procedure, pass(sv) :: sizeof  => d_mumps_solver_sizeof
    procedure, pass(sv) :: cseti   => d_mumps_solver_cseti
    procedure, pass(sv) :: csetr   => d_mumps_solver_csetr
    procedure, pass(sv) :: default => d_mumps_solver_default
    procedure, nopass   :: get_fmt => d_mumps_solver_get_fmt
    procedure, nopass   :: get_id  => d_mumps_solver_get_id
#if defined(HAVE_FINAL) 

    final               :: d_mumps_solver_finalize
#endif
  end type mld_d_mumps_solver_type


  private :: d_mumps_solver_bld, d_mumps_solver_apply, &
       &  d_mumps_solver_free,   d_mumps_solver_descr, &
       &  d_mumps_solver_sizeof, d_mumps_solver_apply_vect,&
       &  d_mumps_solver_cseti, d_mumps_solver_csetr,   &
       &  d_mumps_solver_default, d_mumps_solver_get_fmt, &
       &  d_mumps_solver_get_id
#if defined(HAVE_FINAL) 
  private :: d_mumps_solver_finalize
#endif

  interface 
    subroutine d_mumps_solver_apply_vect(alpha,sv,x,beta,y,desc_data,&
         & trans,work,wv,info,init,initu)
      import :: psb_desc_type, mld_d_mumps_solver_type, psb_d_vect_type, psb_dpk_, psb_spk_, &
           & psb_dspmat_type, psb_d_base_sparse_mat, psb_d_base_vect_type, psb_ipk_
      implicit none 
      type(psb_desc_type), intent(in)      :: desc_data
      class(mld_d_mumps_solver_type), intent(inout) :: sv
      type(psb_d_vect_type),intent(inout)  :: x
      type(psb_d_vect_type),intent(inout)  :: y
      real(psb_dpk_),intent(in)            :: alpha,beta
      character(len=1),intent(in)           :: trans
      real(psb_dpk_),target, intent(inout) :: work(:)
      type(psb_d_vect_type),intent(inout) :: wv(:)
      integer, intent(out)                 :: info
      character, intent(in), optional                :: init
      type(psb_d_vect_type),intent(inout), optional   :: initu
    end subroutine d_mumps_solver_apply_vect
  end interface

  interface
    subroutine d_mumps_solver_apply(alpha,sv,x,beta,y,desc_data,trans,work,info,init,initu)
      import :: psb_desc_type, mld_d_mumps_solver_type, psb_d_vect_type, psb_dpk_, psb_spk_, &
           & psb_dspmat_type, psb_d_base_sparse_mat, psb_d_base_vect_type, psb_ipk_
      implicit none 
      type(psb_desc_type), intent(in)      :: desc_data
      class(mld_d_mumps_solver_type), intent(inout) :: sv
      real(psb_dpk_),intent(inout)         :: x(:)
      real(psb_dpk_),intent(inout)         :: y(:)
      real(psb_dpk_),intent(in)            :: alpha,beta
      character(len=1),intent(in)          :: trans
      real(psb_dpk_),target, intent(inout) :: work(:)
      integer(psb_ipk_), intent(out)                 :: info
      character, intent(in), optional       :: init
      real(psb_dpk_),intent(inout), optional :: initu(:)
    end subroutine d_mumps_solver_apply
  end interface

  interface
    subroutine d_mumps_solver_bld(a,desc_a,sv,info,b,amold,vmold,imold)

      import :: psb_desc_type, mld_d_mumps_solver_type, psb_d_vect_type, psb_dpk_, &
           & psb_dspmat_type, psb_d_base_sparse_mat, psb_d_base_vect_type,&
           & psb_ipk_, psb_i_base_vect_type

      Implicit None

      ! Arguments
      type(psb_dspmat_type), intent(in), target           :: a
      Type(psb_desc_type), Intent(in)                     :: desc_a 
      class(mld_d_mumps_solver_type), intent(inout)       :: sv
      integer(psb_ipk_), intent(out)                      :: info
      type(psb_dspmat_type), intent(in), target, optional :: b
      class(psb_d_base_sparse_mat), intent(in), optional  :: amold
      class(psb_d_base_vect_type), intent(in), optional   :: vmold
      class(psb_i_base_vect_type), intent(in), optional   :: imold
    end subroutine d_mumps_solver_bld
  end interface

contains

  subroutine d_mumps_solver_free(sv,info)
    use psb_base_mod, only : psb_exit
    Implicit None

    ! Arguments
    class(mld_d_mumps_solver_type), intent(inout) :: sv
    integer(psb_ipk_), intent(out)                :: info
    Integer(psb_ipk_) :: err_act
    character(len=20)  :: name='d_mumps_solver_free'

    call psb_erractionsave(err_act)
#if defined(HAVE_MUMPS_)
    if (allocated(sv%id)) then      
      if (sv%built) then 
        sv%id%job = -2
        call dmumps(sv%id)
        info = sv%id%infog(1)
        if (info /= psb_success_) goto 9999
      end if
      deallocate(sv%id, sv%icntl, sv%rcntl)
      if (allocated(sv%local_ictxt)) then
        call psb_exit(sv%local_ictxt,close=.false.)
        deallocate(sv%local_ictxt,stat=info)
      end if
      if (allocated(sv%icntl)) deallocate(sv%icntl,stat=info)
      if (allocated(sv%rcntl)) deallocate(sv%rcntl,stat=info)
      
      sv%built=.false.
    end if
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
#endif
  end subroutine d_mumps_solver_free

#if defined(HAVE_FINAL)
  subroutine d_mumps_solver_finalize(sv)

    Implicit None

    ! Arguments
    type(mld_d_mumps_solver_type), intent(inout) :: sv 
    integer :: info
    Integer :: err_act
    character(len=20)  :: name='d_mumps_solver_finalize'

    call sv%free(info) 

    return

  end subroutine d_mumps_solver_finalize
#endif

  subroutine d_mumps_solver_descr(sv,info,iout,coarse)

    Implicit None

    ! Arguments
    class(mld_d_mumps_solver_type), intent(in) :: sv
    integer(psb_ipk_), intent(out)                     :: info
    integer(psb_ipk_), intent(in), optional            :: iout
    logical, intent(in), optional       :: coarse

    ! Local variables
    integer(psb_ipk_)      :: err_act
    integer(psb_ipk_)      :: ictxt, me, np
    character(len=20), parameter :: name='mld_z_mumps_solver_descr'
    integer(psb_ipk_) :: iout_

    call psb_erractionsave(err_act)
    info = psb_success_
    if (present(iout)) then 
      iout_ = iout 
    else
      iout_ = psb_out_unit
    endif

    write(iout_,*) '  MUMPS  Solver. '

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine d_mumps_solver_descr

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!  WARNING: OTHER PARAMETERS OF MUMPS COULD BE ADDED.                      !!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


  subroutine d_mumps_solver_cseti(sv,what,val,info,idx)

    Implicit None

    ! Arguments
    class(mld_d_mumps_solver_type), intent(inout) :: sv
    character(len=*), intent(in)                  :: what
    integer(psb_ipk_), intent(in)                 :: val
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_), intent(in), optional       :: idx
    integer(psb_ipk_)  :: err_act
    character(len=20)  :: name='d_mumps_solver_cseti'

    info = psb_success_
    call psb_erractionsave(err_act)

    select case(psb_toupper(what))
#if defined(HAVE_MUMPS_)
    case('MUMPS_LOC_GLOB')
      sv%ipar(1)=val
    case('MUMPS_PRINT_ERR')
      sv%ipar(2)=val
    case('MUMPS_IPAR_ENTRY')
      if(present(idx)) then
        ! Note: this will allocate %item
        sv%icntl(idx)%item = val
      end if
#endif
    case default
      call sv%mld_d_base_solver_type%set(what,val,info,idx=idx)
    end select

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine d_mumps_solver_cseti

  subroutine d_mumps_solver_csetr(sv,what,val,info,idx)

    Implicit None

    ! Arguments
    class(mld_d_mumps_solver_type), intent(inout) :: sv
    character(len=*), intent(in)                  :: what
    real(psb_dpk_), intent(in)                 :: val
    integer(psb_ipk_), intent(out)                :: info
    integer(psb_ipk_), intent(in), optional       :: idx
    integer(psb_ipk_)  :: err_act
    character(len=20)  :: name='d_mumps_solver_csetr'

    info = psb_success_
    call psb_erractionsave(err_act)

    select case(psb_toupper(what))
#if defined(HAVE_MUMPS_)
    case('MUMPS_RPAR_ENTRY')
      if(present(idx)) then 
        ! Note: this will allocate %item
        sv%rcntl(idx)%item = val
      end if
#endif
    case default
      call sv%mld_d_base_solver_type%set(what,val,info,idx=idx)
    end select

    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return
  end subroutine d_mumps_solver_csetr

  !!NOTE: BY DEFAULT BLR is activated with a dropping parameter to 1d-4       !!
  subroutine d_mumps_solver_default(sv)

    Implicit none

    !Argument
    class(mld_d_mumps_solver_type),intent(inout) :: sv
    integer(psb_ipk_) :: info
    integer(psb_ipk_)  :: err_act,ictx,icomm
    character(len=20)  :: name='d_mumps_default'

    info = psb_success_
    call psb_erractionsave(err_act)

#if defined(HAVE_MUMPS_)
    if (.not.allocated(sv%id)) then 
      allocate(sv%id,stat=info)
      if (info /= psb_success_) then
        info=psb_err_alloc_dealloc_
        call psb_errpush(info,name,a_err='mld_dmumps_default')
        goto 9999
      end if
      sv%built=.false.
    end if
    if (.not.allocated(sv%icntl)) then
      allocate(sv%icntl(mld_mumps_icntl_size),stat=info)
      if (info /= psb_success_) then
        info=psb_err_alloc_dealloc_
        call psb_errpush(info,name,a_err='mld_dmumps_default')
        goto 9999
      end if
    end if
    if (.not.allocated(sv%rcntl)) then
      allocate(sv%rcntl(mld_mumps_rcntl_size),stat=info)
      if (info /= psb_success_) then
        info=psb_err_alloc_dealloc_
        call psb_errpush(info,name,a_err='mld_dmumps_default')
        goto 9999
      end if
    end if
    ! INSTANTIATION OF sv%id needed to set parmater but mpi communicator needed
    ! sv%id%job = -1
    ! sv%id%par=1
    ! call dmumps(sv%id)
    sv%ipar    = 0
    sv%ipar(1) = mld_global_solver_
    !sv%ipar(10)=6
    !sv%ipar(11)=0
    !sv%ipar(12)=6

#endif
    call psb_erractionrestore(err_act)
    return

9999 continue
    call psb_erractionrestore(err_act)
    if (err_act == psb_act_abort_) then
      call psb_error()
      return
    end if
    return

  end subroutine d_mumps_solver_default

  function d_mumps_solver_sizeof(sv) result(val)

    implicit none 
    ! Arguments
    class(mld_d_mumps_solver_type), intent(in) :: sv
    integer(psb_epk_) :: val
    integer             :: i
#if defined(HAVE_MUMPS_)
    val = (sv%id%INFOG(22)+sv%id%INFOG(32))*1d+6
#else
    val = 0 
#endif
    ! val = 2*psb_sizeof_ip + psb_sizeof_dp
    ! val = val + sv%symbsize
    ! val = val + sv%numsize
    return
  end function d_mumps_solver_sizeof

  function d_mumps_solver_get_fmt() result(val)
    implicit none 
    character(len=32)  :: val

    val = "MUMPS solver"
  end function d_mumps_solver_get_fmt

  function d_mumps_solver_get_id() result(val)
    implicit none 
    integer(psb_ipk_)  :: val

    val = mld_mumps_
  end function d_mumps_solver_get_id
#endif

end module mld_d_mumps_solver

