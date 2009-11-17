VE 0 0 3 0 0 0
MODULE MLD_D_PREC_TYPE,0 0
FILE 0,mld_d_prec_type.f90
USE MLD_BASE_PREC_TYPE 2
REF PSB_D_BASE_PREC_TYPE(PSB_D_BASE_PREC_TYPE@PSB_D_PREC_TYPE),1
REF PSB_DPREC_TYPE(PSB_DPREC_TYPE@PSB_D_PREC_TYPE),1
TYPE MLD_D_BASE_SOLVER_TYPE,1,192,0
ENDTYPE
TYPE MLD_D_BASE_SMOOTHER_TYPE,1,2272,12
  SV(0): 7,MLD_D_BASE_SOLVER_TYPE,b,0,0,400,1,1000000,4000010,0
CONTAINS
TBP BUILD,A1,PASS(SM):D_BASE_SMOOTHER_BLD
TBP APPLY,A1,PASS(SM):D_BASE_SMOOTHER_APPLY
ENDTYPE
TYPE MLD_DBASEPREC_TYPE,1,2160,496
(PSB_D_BASE_PREC_TYPE)
  SM(0): 7,MLD_D_BASE_SMOOTHER_TYPE,b,0,0,400,1,1000000,4000010,0
  AV(12): 7,PSB_D_SPARSE_MAT,b,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
  D(32): 2,2,5,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
  DESC_DATA(52): 7,PSB_DESC_TYPE,b,0,0,0,1,0,0,0
  IPRCPARM(416): 1,3,3,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
  RPRCPARM(436): 2,2,5,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
  PERM(456): 1,3,3,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
  INVPERM(476): 1,3,3,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
CONTAINS
ENDTYPE
TYPE MLD_DONELEV_TYPE,1,112,1740
  PREC(0): 7,MLD_DBASEPREC_TYPE,b,0,0,0,1,0,0,0
  IPRCPARM(496): 1,3,3,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
  RPRCPARM(516): 2,2,5,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
  AC(536): 7,PSB_D_SPARSE_MAT,b,0,0,0,1,0,0,0
  DESC_AC(548): 7,PSB_DESC_TYPE,b,0,0,0,1,0,0,0
  BASE_A(912): 7,PSB_D_SPARSE_MAT,b,0,0,20,1,0,0,0
= NULL
  BASE_DESC(916): 7,PSB_DESC_TYPE,b,0,0,20,1,0,0,0
= NULL
  MAP(920): 7,PSB_DLINMAP_TYPE,b,0,0,0,1,0,0,0
ENDTYPE
TYPE MLD_DPREC_TYPE,1,2272,32
(PSB_DPREC_TYPE)
  PRECV(12): 7,MLD_DONELEV_TYPE,b,0,1,400,1 (1,8,0: 1,0,5,3),1000000,0,0
CONTAINS
TBP D_APPLY2V,A1,PASS(PREC):MLD_D_APPLY2V
TBP D_APPLY1V,A1,PASS(PREC):MLD_D_APPLY1V
ENDTYPE
GMODPROC MLD_NULLIFY_ONELEVPREC: MLD_NULLIFY_D_ONELEVPREC
GMODPROC MLD_PRECFREE: MLD_DPREC_FREE
GMODPROC MLD_PRECFREE: MLD_D_ONELEV_PRECFREE
GMODPROC MLD_PRECFREE: MLD_DBASE_PRECFREE
GMODPROC MLD_SIZEOF: MLD_D_ONELEV_PREC_SIZEOF
GMODPROC MLD_SIZEOF: MLD_DBASEPREC_SIZEOF
GMODPROC MLD_SIZEOF: MLD_DPREC_SIZEOF
GMODPROC MLD_NULLIFY_BASEPREC: MLD_NULLIFY_DBASEPREC
GMODPROC MLD_PRECDESCR: MLD_DFILE_PREC_DESCR
PROC MLD_D_APPLY2V,7,8,0,17: 8,0,0,0,0,40000,1,0,80000,0
USE PSB_BASE_MOD 2
VAR PREC,3,,: 7,MLD_DPREC_TYPE,b,0,0,3,0,0,4000010,1
VAR X,3,,: 2,2,5,0,1,3,0 (1,5,0: 1,0,5,3),0,1000,1
VAR Y,3,,: 2,2,5,0,1,3,0 (1,5,0: 1,0,5,3),0,1000,3
VAR DESC_DATA,3,,: 7,PSB_DESC_TYPE,b,0,0,3,0,0,1000,1
VAR INFO,3,,: 1,3,3,0,0,83,0,0,1000,2
VAR TRANS,3,,: 3,1,a,1,0,13,0,0,1000,0
VAR WORK,3,,: 2,2,5,0,1,1013,0 (1,5,0: 1,0,5,3),0,1000,3
ENDPROC
PROC D_BASE_SMOOTHER_BLD,5,8,0,17: 8,0,0,0,0,40000,1,0,80000,0
USE PSB_BASE_MOD 2
VAR A,3,,: 7,PSB_D_SPARSE_MAT,b,0,0,1003,0,0,0,1
VAR DESC_A,3,,: 7,PSB_DESC_TYPE,b,0,0,3,0,0,0,1
VAR SM,3,,: 7,MLD_D_BASE_SMOOTHER_TYPE,b,0,0,3,0,0,4000010,1
VAR UPD,3,,: 3,1,a,1,0,3,0,0,0,1
VAR INFO,3,,: 1,3,3,0,0,83,0,0,1000,2
ENDPROC
PROC MLD_DPRECAPLY1,5,10,0,17: 8,0,0,0,0,40000,1,0,40000,0
IMPORT MLD_DPREC_TYPE
USE PSB_BASE_MOD 2,ONLY:PSB_DPK_=>PSB_DPK_,PSB_DESC_TYPE=>PSB_DESC_TYPE,PSB_D_SPARSE_MAT=>PSB_D_SPARSE_MAT
VAR PREC,3,,: 7,MLD_DPREC_TYPE,b,0,0,3,0,0,0,1
VAR X,3,,: 2,2,5,0,1,3,0 (1,5,0: 1,0,5,3),0,0,3
VAR DESC_DATA,3,,: 7,PSB_DESC_TYPE,b,0,0,3,0,0,0,1
VAR INFO,3,,: 1,3,3,0,0,3,0,0,0,2
VAR TRANS,3,,: 3,1,a,1,0,13,0,0,0,0
ENDPROC
PROC MLD_DFILE_PREC_DESCR,3,8,0,17: 8,0,0,0,0,40000,1,0,40000,0
VAR P,3,,: 7,MLD_DPREC_TYPE,b,0,0,103,0,0,0,1
VAR INFO,3,,: 1,3,3,0,0,83,0,0,1000,2
VAR IOUT,3,,: 1,3,3,0,0,113,0,0,0,1
ENDPROC
PROC MLD_D_APPLY1V,5,8,0,17: 8,0,0,0,0,40000,1,0,80000,0
USE PSB_BASE_MOD 2
VAR PREC,3,,: 7,MLD_DPREC_TYPE,b,0,0,3,0,0,4000010,1
VAR X,3,,: 2,2,5,0,1,3,0 (1,5,0: 1,0,5,3),0,1000,3
VAR DESC_DATA,3,,: 7,PSB_DESC_TYPE,b,0,0,3,0,0,1000,1
VAR INFO,3,,: 1,3,3,0,0,83,0,0,1000,2
VAR TRANS,3,,: 3,1,a,1,0,13,0,0,1000,0
ENDPROC
PROC MLD_D_ONELEV_PREC_SIZEOF,1,8,0,17: 1,4,e,0,0,40181,1,0,40000,0
RESULTVAR VAL,4,,MLD_D_ONELEV_PREC_SIZEOF: 1,4,e,0,0,181,0,0,0,0
VAR PREC,3,,: 7,MLD_DONELEV_TYPE,b,0,0,103,0,0,0,1
ENDPROC
PROC MLD_DPRECAPLY,7,10,0,17: 8,0,0,0,0,40000,1,0,40000,0
IMPORT MLD_DPREC_TYPE
USE PSB_BASE_MOD 2,ONLY:PSB_DPK_=>PSB_DPK_,PSB_DESC_TYPE=>PSB_DESC_TYPE,PSB_D_SPARSE_MAT=>PSB_D_SPARSE_MAT
VAR PREC,3,,: 7,MLD_DPREC_TYPE,b,0,0,3,0,0,0,1
VAR X,3,,: 2,2,5,0,1,3,0 (1,5,0: 1,0,5,3),0,0,1
VAR Y,3,,: 2,2,5,0,1,3,0 (1,5,0: 1,0,5,3),0,0,3
VAR DESC_DATA,3,,: 7,PSB_DESC_TYPE,b,0,0,3,0,0,0,1
VAR INFO,3,,: 1,3,3,0,0,3,0,0,0,2
VAR TRANS,3,,: 3,1,a,1,0,13,0,0,0,0
VAR WORK,3,,: 2,2,5,0,1,1013,0 (1,5,0: 1,0,5,3),0,0,3
ENDPROC
PROC MLD_DPREC_FREE,2,8,0,17: 8,0,0,0,0,40000,1,0,40000,0
USE PSB_BASE_MOD 2
VAR P,3,,: 7,MLD_DPREC_TYPE,b,0,0,183,0,0,0,3
VAR INFO,3,,: 1,3,3,0,0,83,0,0,1000,2
ENDPROC
PROC D_BASE_SMOOTHER_APPLY,9,8,0,17: 8,0,0,0,0,40000,1,0,80000,0
USE PSB_BASE_MOD 2
VAR ALPHA,3,,: 2,2,5,0,0,3,0,0,0,1
VAR SM,3,,: 7,MLD_D_BASE_SMOOTHER_TYPE,b,0,0,3,0,0,4000010,1
VAR X,3,,: 2,2,5,0,1,3,0 (1,5,0: 1,0,5,3),0,0,1
VAR BETA,3,,: 2,2,5,0,0,3,0,0,0,1
VAR Y,3,,: 2,2,5,0,1,3,0 (1,5,0: 1,0,5,3),0,0,3
VAR DESC_DATA,3,,: 7,PSB_DESC_TYPE,b,0,0,3,0,0,0,1
VAR TRANS,3,,: 3,1,a,1,0,3,0,0,0,1
VAR WORK,3,,: 2,2,5,0,1,1003,0 (1,5,0: 1,0,5,3),0,0,3
VAR INFO,3,,: 1,3,3,0,0,83,0,0,1000,2
ENDPROC
PROC MLD_DBASEPREC_SIZEOF,1,8,0,17: 1,4,e,0,0,40181,1,0,40000,0
RESULTVAR VAL,4,,MLD_DBASEPREC_SIZEOF: 1,4,e,0,0,181,0,0,0,0
VAR PREC,3,,: 7,MLD_DBASEPREC_TYPE,b,0,0,103,0,0,0,1
ENDPROC
PROC MLD_NULLIFY_D_ONELEVPREC,1,8,0,17: 8,0,0,0,0,40000,1,0,40000,0
VAR P,3,,: 7,MLD_DONELEV_TYPE,b,0,0,83,0,0,0,3
ENDPROC
PROC MLD_DBASE_PRECFREE,2,8,0,17: 8,0,0,0,0,40000,1,0,40000,0
VAR P,3,,: 7,MLD_DBASEPREC_TYPE,b,0,0,183,0,0,1000,3
VAR INFO,3,,: 1,3,3,0,0,183,0,0,1000,2
ENDPROC
PROC MLD_DPREC_SIZEOF,1,8,0,17: 1,4,e,0,0,40181,1,0,40000,0
RESULTVAR VAL,4,,MLD_DPREC_SIZEOF: 1,4,e,0,0,181,0,0,0,0
VAR PREC,3,,: 7,MLD_DPREC_TYPE,b,0,0,103,0,0,0,1
ENDPROC
PROC NULL,0,6,161,17: 0,0,0,118,0,20000,1,0,0,0
ENDPROC
PROC MLD_NULLIFY_DBASEPREC,1,8,0,17: 8,0,0,0,0,40000,1,0,40000,0
VAR P,3,,: 7,MLD_DBASEPREC_TYPE,b,0,0,3,0,0,0,3
ENDPROC
PROC MLD_D_ONELEV_PRECFREE,2,8,0,17: 8,0,0,0,0,40000,1,0,40000,0
VAR P,3,,: 7,MLD_DONELEV_TYPE,b,0,0,183,0,0,1000,3
VAR INFO,3,,: 1,3,3,0,0,83,0,0,1000,2
ENDPROC
GENERIC MLD_PRECAPLY: MLD_DPRECAPLY1,MLD_DPRECAPLY
END
