include ../../../Make.inc
LIBDIR=../../../lib
INCDIR=../../../include
MODDIR=../../../modules 
HERE=../..

FINCLUDES=$(FMFLAG)$(HERE) $(FMFLAG)$(MODDIR) $(FMFLAG)$(INCDIR) $(PSBLAS_INCLUDES)



OBJS=mld_c_base_onelev_build.o \
mld_c_base_onelev_check.o \
mld_c_base_onelev_cnv.o \
mld_c_base_onelev_csetc.o \
mld_c_base_onelev_cseti.o \
mld_c_base_onelev_csetr.o \
mld_c_base_onelev_descr.o \
mld_c_base_onelev_dump.o \
mld_c_base_onelev_free.o \
mld_c_base_onelev_mat_asb.o \
mld_c_base_onelev_setag.o \
mld_c_base_onelev_setsm.o \
mld_c_base_onelev_setsv.o \
mld_d_base_onelev_build.o \
mld_d_base_onelev_check.o \
mld_d_base_onelev_cnv.o \
mld_d_base_onelev_csetc.o \
mld_d_base_onelev_cseti.o \
mld_d_base_onelev_csetr.o \
mld_d_base_onelev_descr.o \
mld_d_base_onelev_dump.o \
mld_d_base_onelev_free.o \
mld_d_base_onelev_mat_asb.o \
mld_d_base_onelev_setag.o \
mld_d_base_onelev_setsm.o \
mld_d_base_onelev_setsv.o \
mld_s_base_onelev_build.o \
mld_s_base_onelev_check.o \
mld_s_base_onelev_cnv.o \
mld_s_base_onelev_csetc.o \
mld_s_base_onelev_cseti.o \
mld_s_base_onelev_csetr.o \
mld_s_base_onelev_descr.o \
mld_s_base_onelev_dump.o \
mld_s_base_onelev_free.o \
mld_s_base_onelev_mat_asb.o \
mld_s_base_onelev_setag.o \
mld_s_base_onelev_setsm.o \
mld_s_base_onelev_setsv.o \
mld_z_base_onelev_build.o \
mld_z_base_onelev_check.o \
mld_z_base_onelev_cnv.o \
mld_z_base_onelev_csetc.o \
mld_z_base_onelev_cseti.o \
mld_z_base_onelev_csetr.o \
mld_z_base_onelev_descr.o \
mld_z_base_onelev_dump.o \
mld_z_base_onelev_free.o \
mld_z_base_onelev_mat_asb.o \
mld_z_base_onelev_setag.o \
mld_z_base_onelev_setsm.o \
mld_z_base_onelev_setsv.o 


LIBNAME=libmld_prec.a

lib:  $(OBJS) 
	$(AR) $(HERE)/$(LIBNAME) $(OBJS)
	$(RANLIB) $(HERE)/$(LIBNAME)

mpobjs: 
	(make $(MPFOBJS) FC="$(MPFC)" FCOPT="$(FCOPT)")
	(make $(MPCOBJS) CC="$(MPCC)" CCOPT="$(CCOPT)")

veryclean: clean
	/bin/rm -f $(LIBNAME)

clean:
	/bin/rm -f $(OBJS) $(LOCAL_MODS)
