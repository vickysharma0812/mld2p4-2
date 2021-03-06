!  
!   
!                             MLD2P4  version 2.2
!    MultiLevel Domain Decomposition Parallel Preconditioners Package
!               based on PSBLAS (Parallel Sparse BLAS version 3.0)
!    
!    (C) Copyright 2008,2009,2010,2012,2013
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
  subroutine z_mumps_solver_bld(a,desc_a,sv,info,b,amold,vmold,imold)

    use psb_base_mod
    use mld_z_mumps_solver
    Implicit None

    ! Arguments
    type(psb_zspmat_type)                               :: c 
    type(psb_zspmat_type), intent(in), target           :: a
    Type(psb_desc_type), Intent(in)                     :: desc_a 
    class(mld_z_mumps_solver_type), intent(inout)       :: sv
    integer(psb_ipk_), intent(out)                      :: info
    type(psb_zspmat_type), intent(in), target, optional :: b
    class(psb_z_base_sparse_mat), intent(in), optional  :: amold
    class(psb_z_base_vect_type), intent(in), optional   :: vmold
    class(psb_i_base_vect_type), intent(in), optional   :: imold
    ! Local variables
    type(psb_zspmat_type)      :: atmp
    type(psb_z_coo_sparse_mat), target :: acoo
    integer(psb_ipk_)  :: n_row,n_col, nrow_a, nztota, nglob, nglobrec, nzt, npr, npc
    integer(psb_ipk_)  :: ifrst, ibcheck
    integer(psb_ipk_)  :: ictxt, ictxt1, icomm, np, iam, me, i, err_act, debug_unit, debug_level
    character(len=20)  :: name='z_mumps_solver_bld', ch_err

#if defined(HAVE_MUMPS_) && !defined(LPK8) 

    info=psb_success_

  call psb_erractionsave(err_act)
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()
  ictxt       = desc_a%get_context()
  call psb_info(ictxt, iam, np)      
  if (sv%ipar(1) == mld_local_solver_ ) then
    call psb_init(ictxt1,np=1,basectxt=ictxt,ids=(/iam/))
    call psb_get_mpicomm(ictxt1, icomm)
    allocate(sv%local_ictxt,stat=info)
    sv%local_ictxt = ictxt1
    !write(*,*)iam,'mumps_bld: local +++++>',icomm,sv%local_ictxt
    call psb_info(ictxt1, me, np)
    npr  = np
  else if (sv%ipar(1) == mld_global_solver_ ) then
    call psb_get_mpicomm(ictxt,icomm)
    !write(*,*)iam,'mumps_bld: global +++++>',icomm,ictxt
    call psb_info(ictxt, iam, np)
    me = iam 
    npr  = np
  else
    info = psb_err_internal_error_
    call psb_errpush(info,name,& 
           & a_err='Invalid local/global solver in MUMPS')
    goto 9999
  end if
  npc  = 1
  if (debug_level >= psb_debug_outer_) &
       & write(debug_unit,*) me,' ',trim(name),' start'
  !    if (allocated(sv%id)) then 
  !      call sv%free(info)

  !     deallocate(sv%id)
  !   end if
  if(.not.allocated(sv%id)) then
    allocate(sv%id,stat=info)
    if (info /= psb_success_) then
      info=psb_err_alloc_dealloc_
      call psb_errpush(info,name,a_err='mld_dmumps_default')
      goto 9999
    end if
  end if


  sv%id%comm    =  icomm
  sv%id%job     = -1
  sv%id%par     =  1
  call zmumps(sv%id)   
  !WARNING: CALLING dMUMPS WITH JOB=-1 DESTROY THE SETTING OF DEFAULT:TO FIX
  if (allocated(sv%icntl)) then 
    do i=1,mld_mumps_icntl_size
      if (allocated(sv%icntl(i)%item)) then
        !write(0,*) 'MUMPS_BLD: setting entry ',i,' to ', sv%icntl(i)%item
        sv%id%icntl(i) = sv%icntl(i)%item
      end if
    end do
  end if
  if (allocated(sv%rcntl)) then 
    do i=1,mld_mumps_rcntl_size
      if (allocated(sv%rcntl(i)%item)) sv%id%cntl(i) = sv%rcntl(i)%item
    end do
  end if
  sv%id%icntl(3)=sv%ipar(2)

  nglob  = desc_a%get_global_rows()
  if (sv%ipar(1) == mld_local_solver_ ) then
    nglobrec=desc_a%get_local_rows()
    call a%csclip(c,info,jmax=a%get_nrows())
    call c%cp_to(acoo)
    nglob = c%get_nrows()
    if (nglobrec /= nglob) then
      write(*,*)'WARNING: MUMPS solver does not allow overlap in AS yet. '
      write(*,*)'A zero-overlap is used instead'
    end if
  else
    call a%cp_to(acoo)
  end if
  nztota = acoo%get_nzeros()

  ! switch to global numbering
  if (sv%ipar(1) == mld_global_solver_ ) then
    call psb_loc_to_glob(acoo%ja(1:nztota), desc_a, info, iact='I')
    call psb_loc_to_glob(acoo%ia(1:nztota), desc_a, info, iact='I')
  end if
  sv%id%irn_loc   => acoo%ia
  sv%id%jcn_loc   => acoo%ja
  sv%id%a_loc     => acoo%val
  sv%id%icntl(18) = 3
  if(acoo%is_upper() .or. acoo%is_lower()) then
    sv%id%sym = 2
  else
    sv%id%sym = 0
  end if
  sv%id%n      = nglob
  ! there should be a better way for this
  sv%id%nnz_loc = acoo%get_nzeros()
  sv%id%nnz     = acoo%get_nzeros()
  sv%id%job    = 4
  if (sv%ipar(1) == mld_global_solver_ ) then
    call psb_sum(ictxt,sv%id%nnz)
  end if
  !call psb_barrier(ictxt)
  write(*,*)iam, ' calling mumps N,nz,nz_loc',sv%id%n,sv%id%nnz,sv%id%nnz_loc
  call dmumps(sv%id)
  !call psb_barrier(ictxt)
  info = sv%id%infog(1)
  if (info /= psb_success_) then
    info=psb_err_from_subroutine_
    ch_err='mld_dmumps_fact '
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if
  nullify(sv%id%irn)
  nullify(sv%id%jcn)
  nullify(sv%id%a)

  call acoo%free()
  sv%built=.true.

  if (debug_level >= psb_debug_outer_) &
       & write(debug_unit,*) iam,' ',trim(name),' end'

  call psb_erractionrestore(err_act)
  return

9999 continue
  call psb_erractionrestore(err_act)
  if (err_act == psb_act_abort_) then
    call psb_error()
    return
  end if
  return
#else
  write(psb_err_unit,*) "MUMPS Not Configured, fix make.inc and recompile "
#endif
end subroutine z_mumps_solver_bld

