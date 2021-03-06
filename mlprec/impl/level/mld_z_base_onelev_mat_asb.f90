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
! File: mld_z_onelev_mat_asb.f90
!
! Subroutine: mld_z_onelev_mat_asb
! Version:    complex
!
!  This routine builds the matrix associated to the current level of the
!  multilevel preconditioner from the matrix associated to the previous level,
!  by using the user-specified aggregation technique (therefore, it also builds the
!  prolongation and restriction operators mapping the current level to the
!  previous one and vice versa). 
!  The current level is regarded as the coarse one, while the previous as
!  the fine one. This is in agreement with the fact that the routine is called,
!  by mld_mlprec_bld, only on levels >=2.
!  The main structure is:
!  1. Perform sanity checks;
!  2. Call mld_Xaggrmat_asb to compute prolongator/restrictor/AC
!  3. According to the choice of DIST/REPL for AC, build a descriptor DESC_AC,
!     and adjust the column numbering of AC/OP_PROL/OP_RESTR
!  4. Pack restrictor and prolongator into p%map
!  5. Fix base_a and base_desc pointers.
!
! 
! Arguments:
!    p       -  type(mld_z_onelev_type), input/output.
!               The 'one-level' data structure containing the control
!               parameters and (eventually) coarse matrix and prolongator/restrictors. 
!               
!    a       -  type(psb_zspmat_type).
!               The sparse matrix structure containing the local part of the
!               fine-level matrix.
!    desc_a  -  type(psb_desc_type), input.
!               The communication descriptor of a.
!    ilaggr     -  integer, dimension(:), input
!                  The mapping between the row indices of the coarse-level
!                  matrix and the row indices of the fine-level matrix.
!                  ilaggr(i)=j means that node i in the adjacency graph
!                  of the fine-level matrix is mapped onto node j in the
!                  adjacency graph of the coarse-level matrix. Note that the indices
!                  are assumed to be shifted so as to make sure the ranges on
!                  the various processes do not   overlap.
!    nlaggr     -  integer, dimension(:) input
!                  nlaggr(i) contains the aggregates held by process i.
!    op_prol    -  type(psb_zspmat_type), input/output
!               The tentative prolongator on input, released on output. 
!               
!    info    -  integer, output.
!               Error code.         
!  
subroutine mld_z_base_onelev_mat_asb(lv,a,desc_a,ilaggr,nlaggr,op_prol,info)

  use psb_base_mod
  use mld_base_prec_type
  use mld_z_onelev_mod, mld_protect_name => mld_z_base_onelev_mat_asb

  implicit none

  ! Arguments
  class(mld_z_onelev_type), intent(inout), target :: lv
  type(psb_zspmat_type), intent(in)  :: a
  type(psb_desc_type), intent(in)    :: desc_a
  integer(psb_lpk_), intent(inout) :: nlaggr(:)
  integer(psb_lpk_), intent(inout) :: ilaggr(:)
  type(psb_lzspmat_type), intent(inout)  :: op_prol
  integer(psb_ipk_), intent(out)      :: info
  

  ! Local variables
  character(len=24)                :: name
  integer(psb_ipk_)               :: ictxt, np, me
  integer(psb_ipk_)                :: err_act
  type(psb_lzspmat_type)           :: lac, lac1, op_restr
  type(psb_zspmat_type)            :: ac, iop_restr, iop_prol
  type(psb_lz_coo_sparse_mat)       :: acoo, bcoo
  type(psb_lz_csr_sparse_mat)       :: acsr1
  integer(psb_lpk_)                :: ntaggr, nr, nc
  integer(psb_ipk_)                :: nzl, inl
  integer(psb_ipk_)            :: debug_level, debug_unit

  name='mld_z_onelev_mat_asb'
  call psb_erractionsave(err_act)
  if (psb_errstatus_fatal()) then
    info = psb_err_internal_error_; goto 9999
  end if
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()
  info  = psb_success_
  ictxt = desc_a%get_context()
  call psb_info(ictxt,me,np)

  call mld_check_def(lv%parms%aggr_prol,'Smoother',&
       &   mld_smooth_prol_,is_legal_ml_aggr_prol)
  call mld_check_def(lv%parms%coarse_mat,'Coarse matrix',&
       &   mld_distr_mat_,is_legal_ml_coarse_mat)
  call mld_check_def(lv%parms%aggr_filter,'Use filtered matrix',&
       &   mld_no_filter_mat_,is_legal_aggr_filter)
  call mld_check_def(lv%parms%aggr_omega_alg,'Omega Alg.',&
       &   mld_eig_est_,is_legal_ml_aggr_omega_alg)
  call mld_check_def(lv%parms%aggr_eig,'Eigenvalue estimate',&
       &   mld_max_norm_,is_legal_ml_aggr_eig)
  call mld_check_def(lv%parms%aggr_omega_val,'Omega',dzero,is_legal_d_omega)


  !
  ! Build the coarse-level matrix from the fine-level one, starting from 
  ! the mapping defined by mld_aggrmap_bld and applying the aggregation
  ! algorithm specified by lv%iprcparm(mld_aggr_prol_)
  !
  call lv%aggr%mat_asb(lv%parms,a,desc_a,ilaggr,nlaggr,lac,op_prol,op_restr,info)

  if(info /= psb_success_) then
    call psb_errpush(psb_err_from_subroutine_,name,a_err='mld_aggrmat_asb')
    goto 9999
  end if


  ! Common code refactored here.

  ntaggr = sum(nlaggr)

  select case(lv%parms%coarse_mat)

  case(mld_distr_mat_) 

    call lac%mv_to(bcoo)
    nzl = bcoo%get_nzeros()
    inl = nlaggr(me+1)
    if (inl < nlaggr(me+1)) then
      info = psb_err_bad_int_cnv_
      call psb_errpush(info,name,&
           & l_err=(/nlaggr(me+1),inl*1_psb_lpk_/))
      goto 9999
    end if
    if (info == psb_success_) call psb_cdall(ictxt,lv%desc_ac,info,nl=inl)
    if (info == psb_success_) call psb_cdins(nzl,bcoo%ia,bcoo%ja,lv%desc_ac,info)
    if (info == psb_success_) call psb_cdasb(lv%desc_ac,info)
    if (info == psb_success_) call psb_glob_to_loc(bcoo%ia(1:nzl),lv%desc_ac,info,iact='I')
    if (info == psb_success_) call psb_glob_to_loc(bcoo%ja(1:nzl),lv%desc_ac,info,iact='I')
    if (info /= psb_success_) then
      call psb_errpush(psb_err_internal_error_,name,&
           & a_err='Creating lv%desc_ac and converting ac')
      goto 9999
    end if
    if (debug_level >= psb_debug_outer_) &
         & write(debug_unit,*) me,' ',trim(name),&
         & 'Assembld aux descr. distr.'
    call lac%mv_from(bcoo)
    call lv%ac%mv_from_l(lac)

    call lv%ac%set_nrows(lv%desc_ac%get_local_rows())
    call lv%ac%set_ncols(lv%desc_ac%get_local_cols())
    call lv%ac%set_asb()

    if (info /= psb_success_) then
      call psb_errpush(psb_err_from_subroutine_,name,a_err='psb_sp_free')
      goto 9999
    end if

    if (np>1) then 
      call op_prol%mv_to(acsr1)
      nzl = acsr1%get_nzeros()
      call psb_glob_to_loc(acsr1%ja(1:nzl),lv%desc_ac,info,'I')
      if(info /= psb_success_) then
        call psb_errpush(psb_err_from_subroutine_,name,a_err='psb_glob_to_loc')
        goto 9999
      end if
      call op_prol%mv_from(acsr1)
    endif
    nc = lv%desc_ac%get_local_cols()
    call op_prol%set_ncols(nc)

    if (np>1) then 
      call op_restr%cscnv(info,type='coo',dupl=psb_dupl_add_)
      call op_restr%mv_to(acoo)
      nzl = acoo%get_nzeros()
      if (info == psb_success_) call psb_glob_to_loc(acoo%ia(1:nzl),lv%desc_ac,info,'I')
      call acoo%set_dupl(psb_dupl_add_)
      if (info == psb_success_) call op_restr%mv_from(acoo)
      if (info == psb_success_) call op_restr%cscnv(info,type='csr')        
      if(info /= psb_success_) then
        call psb_errpush(psb_err_internal_error_,name,&
             & a_err='Converting op_restr to local')
        goto 9999
      end if
    end if
    !
    ! Clip to local rows.
    !
    nr = lv%desc_ac%get_local_rows()
    call op_restr%set_nrows(nr)

    if (debug_level >= psb_debug_outer_) &
         & write(debug_unit,*) me,' ',trim(name),&
         & 'Done ac '

  case(mld_repl_mat_) 
    !
    !
    
    call psb_cdall(ictxt,lv%desc_ac,info,mg=ntaggr,repl=.true.)
    if (info == psb_success_) call psb_cdasb(lv%desc_ac,info)
    if (info == psb_success_) &
         & call psb_gather(lac1,lac,lv%desc_ac,info,dupl=psb_dupl_add_,keeploc=.false.)
    call lv%ac%mv_from_l(lac1)
    if (info /= psb_success_) goto 9999

  case default 
    info = psb_err_internal_error_
    call psb_errpush(info,name,a_err='invalid mld_coarse_mat_')
    goto 9999
  end select

  call lv%ac%cscnv(info,type='csr',dupl=psb_dupl_add_)
  if(info /= psb_success_) then
    call psb_errpush(psb_err_from_subroutine_,name,a_err='spcnv')
    goto 9999
  end if

  !
  ! Copy the prolongation/restriction matrices into the descriptor map.
  !  op_restr => PR^T   i.e. restriction  operator
  !  op_prol => PR     i.e. prolongation operator
  !  
  call iop_restr%mv_from_l(op_restr)
  call iop_prol%mv_from_l(op_prol)
  lv%map = psb_linmap(psb_map_aggr_,desc_a,&
       & lv%desc_ac,iop_restr,iop_prol,ilaggr,nlaggr)
  if (info == psb_success_) call iop_prol%free()
  if (info == psb_success_) call iop_restr%free()
  if(info /= psb_success_) then
    call psb_errpush(psb_err_from_subroutine_,name,a_err='sp_Free')
    goto 9999
  end if
  !
  ! Fix the base_a and base_desc pointers for handling of residuals.
  ! This is correct because this routine is only called at levels >=2.
  !
  lv%base_a    => lv%ac
  lv%base_desc => lv%desc_ac

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)
  return

end subroutine mld_z_base_onelev_mat_asb
