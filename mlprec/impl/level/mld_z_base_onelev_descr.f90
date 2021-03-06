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
subroutine mld_z_base_onelev_descr(lv,il,nl,ilmin,info,iout)
  
  use psb_base_mod
  use mld_z_onelev_mod, mld_protect_name => mld_z_base_onelev_descr
  Implicit None
  ! Arguments
  class(mld_z_onelev_type), intent(in)  :: lv
  integer(psb_ipk_), intent(in)           :: il,nl,ilmin
  integer(psb_ipk_), intent(out)          :: info
  integer(psb_ipk_), intent(in), optional :: iout

  ! Local variables
  integer(psb_ipk_)      :: err_act
  character(len=20), parameter :: name='mld_z_base_onelev_descr'
  integer(psb_ipk_)      :: iout_
  logical      :: coarse


  call psb_erractionsave(err_act)


  coarse = (il==nl)

  if (present(iout)) then 
    iout_ = iout
  else 
    iout_ = psb_out_unit
  end if

  write(iout_,*) 
  if (il == ilmin) then 
    call lv%parms%mlcycledsc(iout_,info)
    if (allocated(lv%aggr)) then
      call lv%aggr%descr(lv%parms,iout_,info)
    else
      write(iout_,*) 'Internal error: unallocated aggregator object'
      info = psb_err_internal_error_
      call psb_errpush(info,name)
      goto 9999
    end if
    write(iout_,*) 
  end if
  
  if (il > 1) then 

    if (coarse)  then 
      write(iout_,*) ' Level ',il,' (coarse)'
    else
      write(iout_,*) ' Level ',il
    end if

    call lv%parms%descr(iout_,info,coarse=coarse)

    if (nl > 1) then 
      if (allocated(lv%map%naggr)) then
        write(iout_,*) '  Coarse Matrix: Global size: ', &
             &  sum(lv%map%naggr(:)),' Nonzeros: ',lv%ac_nz_tot
        write(iout_,*) '          Local matrix sizes: ', &
             &  lv%map%naggr(:)
        write(iout_,*) '  Aggregation   ratio: ', &
             &  lv%szratio
      end if
    end if

    if (coarse.and.allocated(lv%sm)) &
         & call lv%sm%descr(info,iout=iout_,coarse=coarse)
  end if
  
  call psb_erractionrestore(err_act)
  return

9999 call psb_error_handler(err_act)
  return

end subroutine mld_z_base_onelev_descr
