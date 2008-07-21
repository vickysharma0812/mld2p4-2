!!$ 
!!$ 
!!$                           MLD2P4  version 1.0
!!$  MultiLevel Domain Decomposition Parallel Preconditioners Package
!!$             based on PSBLAS (Parallel Sparse BLAS version 2.2)
!!$  
!!$  (C) Copyright 2008
!!$
!!$                      Salvatore Filippone  University of Rome Tor Vergata       
!!$                      Alfredo Buttari      University of Rome Tor Vergata
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
module data_input
  
  interface read_data
    module procedure read_char, read_int,&
         & read_double, read_single
  end interface read_data
  
contains

  subroutine read_char(val,file)
    character(len=*), intent(out) :: val
    integer, intent(in)           :: file
    character(len=1024) :: charbuf
    integer :: idx
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,"!")
    read(charbuf(1:idx-1),'(a)') val
  end subroutine read_char
  subroutine read_int(val,file)
    integer, intent(out) :: val
    integer, intent(in)  :: file
    character(len=1024) :: charbuf
    integer :: idx
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,"!")
    read(charbuf(1:idx-1),*) val
  end subroutine read_int
  subroutine read_single(val,file)
    use psb_base_mod
    real(psb_spk_), intent(out) :: val
    integer, intent(in)         :: file
    character(len=1024) :: charbuf
    integer :: idx
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,"!")
    read(charbuf(1:idx-1),*) val
  end subroutine read_single
  subroutine read_double(val,file)
    use psb_base_mod
    real(psb_dpk_), intent(out) :: val
    integer, intent(in)         :: file
    character(len=1024) :: charbuf
    integer :: idx
    read(file,'(a)')charbuf
    charbuf = adjustl(charbuf)
    idx=index(charbuf,"!")
    read(charbuf(1:idx-1),*) val
  end subroutine read_double
end module data_input
