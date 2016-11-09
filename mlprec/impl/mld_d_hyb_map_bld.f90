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
!
! File: mld_d_dec_map__bld.f90
!
! Subroutine: mld_d_dec_map_bld
! Version:    real
!
!  This routine builds the tentative prolongator based on the
!  decoupled aggregation algorithm presented in
!
!    M. Brezina and P. Vanek, A black-box iterative solver based on a 
!    two-level Schwarz method, Computing,  63 (1999), 233-263.
!    P. D'Ambra, D. di Serafino and S. Filippone, On the development of
!    PSBLAS-based parallel two-level Schwarz preconditioners, Appl. Num. Math.
!    57 (2007), 1181-1196.
!
! Note: upon exit 
!
! Arguments:
!    a       -  type(psb_dspmat_type).
!               The sparse matrix structure containing the local part of the
!               matrix to be preconditioned.
!    desc_a  -  type(psb_desc_type), input.
!               The communication descriptor of a.
!    p       -  type(mld_dprec_type), input/output.
!               The preconditioner data structure; upon exit it contains 
!               the multilevel hierarchy of prolongators, restrictors
!               and coarse matrices.
!    info    -  integer, output.
!               Error code.              
!
!
!
subroutine mld_d_hyb_map_bld(iorder,radius,theta,a,desc_a,nlaggr,ilaggr,info)

  use psb_base_mod
  use mld_d_inner_mod, mld_protect_name => mld_d_hyb_map_bld

  implicit none

  ! Arguments
  integer(psb_ipk_), intent(in)     :: iorder, radius
  type(psb_dspmat_type), intent(in) :: a
  type(psb_desc_type), intent(in)    :: desc_a
  real(psb_dpk_), intent(in)         :: theta
  integer(psb_ipk_), allocatable, intent(out)  :: ilaggr(:),nlaggr(:)
  integer(psb_ipk_), intent(out)               :: info

  ! Local variables
  integer(psb_ipk_), allocatable  :: ils(:), neigh(:), irow(:), icol(:),&
       & ideg(:), idxs(:), tmpaggr(:)
  real(psb_dpk_), allocatable :: val(:), diag(:)  
  real(psb_dpk_), allocatable :: mu_rows(:), mu_cols(:)
  integer(psb_ipk_) :: icnt,nlp,k,n,ia,isz,nr, naggr,i,j,m, nz, ilg, ii, ip
  type(psb_d_csr_sparse_mat) :: acsr, muij, s_neigh
  type(psb_d_coo_sparse_mat) :: s_neigh_coo
  real(psb_dpk_)  :: cpling, tcl
  logical :: disjoint
  integer(psb_ipk_) :: debug_level, debug_unit,err_act
  integer(psb_ipk_) :: ictxt,np,me
  integer(psb_ipk_) :: nrow, ncol, n_ne
  character(len=20)  :: name, ch_err

  if (psb_get_errstatus() /= 0) return 
  info=psb_success_
  name = 'mld_hyb_map_bld'
  call psb_erractionsave(err_act)
  debug_unit  = psb_get_debug_unit()
  debug_level = psb_get_debug_level()
  !
  ictxt=desc_a%get_context()
  call psb_info(ictxt,me,np)
  nrow  = desc_a%get_local_rows()
  ncol  = desc_a%get_local_cols()
  write(0,*) me,trim(name),'Start;'
  nr = a%get_nrows()
  allocate(ilaggr(nr),neigh(nr),ideg(nr),idxs(nr),stat=info)
  if(info /= psb_success_) then
    info=psb_err_alloc_request_
    call psb_errpush(info,name,i_err=(/4*nr,izero,izero,izero,izero/),&
         & a_err='integer')
    goto 9999
  end if
  allocate(mu_rows(nr),mu_cols(nr),stat=info)
  if(info /= psb_success_) then
    info=psb_err_alloc_request_
    call psb_errpush(info,name,i_err=(/2*nr,izero,izero,izero,izero/),&
         & a_err='real(psb_dpk_)')
    goto 9999
  end if
  mu_rows(:) = dzero
  mu_cols(:) = dzero
  
  diag   = a%get_diag(info)
  if(info /= psb_success_) then
    info=psb_err_from_subroutine_
    call psb_errpush(info,name,a_err='psb_sp_getdiag')
    goto 9999
  end if

  !
  ! Phase zero: compute muij
  ! 
  call a%cp_to(muij)
  do i=1, nr
    do k=muij%irp(i),muij%irp(i+1)-1
      j = muij%ja(k)
      if ((j==i).or.(j>nr).or.(muij%val(k)>=0)) then
        muij%val(k) = dzero
      else
        muij%val(k) = -muij%val(k)/sqrt(abs(diag(i)*diag(j)))
      end if
      mu_rows(i) = max(mu_rows(i),muij%val(k))
      mu_cols(j) = max(mu_cols(j),muij%val(k))
    end do
  end do
  !write(*,*) 'murows/cols ',maxval(mu_rows),maxval(mu_cols)
  !
  ! Compute the 1-neigbour
  !
  call s_neigh_coo%allocate(nr,nr,muij%get_nzeros())
  ip = 0 
  do i=1, nr
    do k=muij%irp(i),muij%irp(i+1)-1
      j = muij%ja(k)
      if (muij%val(k) >= theta*min(mu_rows(i),mu_cols(j))) then
        ip = ip + 1
        s_neigh_coo%ia(ip)  = i
        s_neigh_coo%ja(ip)  = j
        s_neigh_coo%val(ip) = done
      end if
    end do
  end do
  !write(*,*) 'S_NEIGH: ',nr,ip
  call s_neigh_coo%set_nzeros(ip)
  call s_neigh%mv_from_coo(s_neigh_coo,info)
  
  !
  ! Figure out the order in which to visit the matrix
  !
  if (iorder == mld_aggr_ord_nat_) then 
    do i=1, nr
      ilaggr(i) = -(nr+1)
      idxs(i)   = i 
    end do
  else 
    do i=1, nr
      ilaggr(i) = -(nr+1)
      ideg(i)   = muij%irp(i+1) - muij%irp(i)
    end do
    call psb_msort(ideg,ix=idxs,dir=psb_sort_down_)
  end if

  !
  ! Phase one: Start with disjoint groups.
  ! 
  naggr = 0
  icnt = 0
  step1: do ii=1, nr
    i = idxs(ii)

    if (ilaggr(i) == -(nr+1)) then 
      !
      ! Get the 1-neighbourhood of I 
      !
      call s_neigh%csget(i,i,nz,irow,icol,val,info)
      if (info /= psb_success_) then 
        info=psb_err_from_subroutine_
        call psb_errpush(info,name,a_err='psb_sp_getrow')
        goto 9999
      end if
      !
      ! If the neighbourhood only contains I, skip it
      !
      if (nz ==0) then
        ilaggr(i) = 0
        cycle step1
      end if
      if ((nz==1).and.(icol(1)==i)) then
        ilaggr(i) = 0
        cycle step1
      end if
      !
      ! If the whole strongly coupled neighborhood of I is
      ! as yet unconnected, turn it into the next aggregate.
      !
      disjoint = all(ilaggr(icol(1:nz)) == -(nr+1)) 
      if (disjoint) then 
        icnt      = icnt + 1 
        naggr     = naggr + 1
        do k=1, nz
          ilaggr(icol(k)) = naggr
        end do
        ilaggr(i) = naggr
      end if
    endif
  enddo step1
  
  if (debug_level >= psb_debug_outer_) then 
    write(debug_unit,*) me,' ',trim(name),&
         & ' Check 1:',count(ilaggr == -(nr+1))
  end if

  !
  ! Phase two: join the neighbours
  !
  tmpaggr = ilaggr
  step2: do ii=1,nr
    i = idxs(ii)

    if (ilaggr(i) == -(nr+1)) then         
      call s_neigh%csget(i,i,nz,irow,icol,val,info)
      if (info /= psb_success_) then 
        info=psb_err_from_subroutine_
        call psb_errpush(info,name,a_err='psb_sp_getrow')
        goto 9999
      end if
      !
      ! Find the most strongly connected neighbour that is
      ! already aggregated, if any, and join its aggregate
      !
      cpling = dzero
      ip = 0
      do k=1, nz
        j   = icol(k)
        if ((1<=j).and.(j<=nr)) then 
          if ( (tmpaggr(j) > 0).and.(val(k) > cpling)) then
            ip = k
            cpling = val(k)
          end if
        end if
      enddo
      if (ip > 0) then 
        ilaggr(i) = ilaggr(icol(ip))
      end if
    end if
  end do step2


  !
  ! Phase three: sweep over leftovers, if any 
  !
  step3: do ii=1,nr
    i = idxs(ii)

    if (ilaggr(i) < 0) then
      call s_neigh%csget(i,i,nz,irow,icol,val,info)
      if (info /= psb_success_) then 
        info=psb_err_from_subroutine_
        call psb_errpush(info,name,a_err='psb_sp_getrow')
        goto 9999
      end if
      !
      ! Find its strongly  connected neighbourhood not 
      ! already aggregated, and make it into a new aggregate.
      !
      ip = 0
      do k=1, nz
        j   = icol(k)
        if ((1<=j).and.(j<=nr)) then 
          if (ilaggr(j) < 0)  then
            ip = ip + 1
            icol(ip) = icol(k)
          end if
        end if
      enddo
      if (ip > 0) then
        icnt      = icnt + 1 
        naggr     = naggr + 1
        ilaggr(i) = naggr
        do k=1, ip
          ilaggr(icol(k)) = naggr
        end do
      end if
    end if
  end do step3

  !write(*,*) 'ILAGGR counts: ',count(ilaggr<0),count(ilaggr==0),count(ilaggr>0),nr
  if (count(ilaggr<0) >0) then 
    info=psb_err_internal_error_
    call psb_errpush(info,name,a_err='Fatal error: some leftovers')
    goto 9999
  endif

  if (naggr > ncol) then 
    write(0,*) name,'Error : naggr > ncol',naggr,ncol
    info=psb_err_internal_error_
    call psb_errpush(info,name,a_err='Fatal error: naggr>ncol')
    goto 9999
  end if

  call psb_realloc(ncol,ilaggr,info)
  if (info /= psb_success_) then 
    info=psb_err_from_subroutine_
    ch_err='psb_realloc'
    call psb_errpush(info,name,a_err=ch_err)
    goto 9999
  end if

  allocate(nlaggr(np),stat=info)
  if (info /= psb_success_) then 
    info=psb_err_alloc_request_
    call psb_errpush(info,name,i_err=(/np,izero,izero,izero,izero/),&
         & a_err='integer')
    goto 9999
  end if

  nlaggr(:) = 0
  nlaggr(me+1) = naggr
  call psb_sum(ictxt,nlaggr(1:np))

  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)

  return

end subroutine mld_d_hyb_map_bld

