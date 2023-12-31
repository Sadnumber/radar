###################################################################################
# GTRACK Usecase Unit Test on DSS Makefile
###################################################################################
.PHONY: gtrackTestDss gtrackTestDssClean

###################################################################################
# Setup the VPATH:
###################################################################################
vpath %.c src
vpath %.c test/usecases/dss
vpath %.c test/common

###################################################################################
# The GTRACK Unit test requires additional libraries
###################################################################################
GTRACK_USECASE_DSS_TEST_STD_LIBS = $(C66_COMMON_STD_LIB)						\
								  -llibgtrack$(MMWAVE_SDK_LIB_BUILD_OPTION)_$(MMWAVE_SDK_DEVICE_TYPE).$(C66_LIB_EXT) \
								  -llibtestlogger_$(MMWAVE_SDK_DEVICE_TYPE).$(C66_LIB_EXT)

GTRACK_USECASE_DSS_TEST_LOC_LIBS = $(C66_COMMON_LOC_LIB)						\
								-ilib \
								-i$(MMWAVE_SDK_INSTALL_PATH)/ti/utils/testlogger/lib

###################################################################################
# Unit Test Files
###################################################################################
GTRACK_USECASE_DSS_TEST_CMD		= $(MMWAVE_SDK_INSTALL_PATH)/ti/platform/$(MMWAVE_SDK_DEVICE_TYPE)
GTRACK_USECASE_DSS_TEST_MAP		= test/usecases/dss/$(MMWAVE_SDK_DEVICE_TYPE)_gtrack$(MMWAVE_SDK_LIB_BUILD_OPTION)_usecase_dss.map
GTRACK_USECASE_DSS_TEST_OUT		= test/usecases/dss/$(MMWAVE_SDK_DEVICE_TYPE)_gtrack$(MMWAVE_SDK_LIB_BUILD_OPTION)_usecase_dss.$(C66_EXE_EXT)
GTRACK_USECASE_DSS_TEST_BIN		= test/usecases/dss/$(MMWAVE_SDK_DEVICE_TYPE)_gtrack$(MMWAVE_SDK_LIB_BUILD_OPTION)_usecase_dss.bin
GTRACK_USECASE_DSS_TEST_APP_CMD	= test/usecases/dss/dss_gtrack_linker.cmd
GTRACK_USECASE_DSS_TEST_SOURCES	= main_dss.c			\
								  gtrackApp.c		\
								  gtrackAlloc.c		\
								  gtrackLog.c

GTRACK_USECASE_DSS_TEST_SOURCES_GEN = ti_board_config.c	\
									  ti_board_open_close.c	\
									  ti_dpl_config.c	\
									  ti_drivers_config.c	\
									  ti_pinmux_config.c	\
									  ti_power_clock_config.c	\
									  ti_drivers_open_close.c

GTRACK_USECASE_DSS_TEST_DEPENDS = $(addprefix $(PLATFORM_OBJDIR)/, $(GTRACK_USECASE_DSS_TEST_SOURCES:.c=.$(C66_DEP_EXT)))
GTRACK_USECASE_DSS_TEST_OBJECTS = $(addprefix $(PLATFORM_OBJDIR)/, $(GTRACK_USECASE_DSS_TEST_SOURCES:.c=.$(C66_OBJ_EXT)))

GTRACK_USECASE_DSS_TEST_DEPENDS += $(addprefix $(PLATFORM_OBJDIR)/dssgenerated/, $(GTRACK_USECASE_DSS_TEST_SOURCES_GEN:.c=.$(C66_DEP_EXT)))
GTRACK_USECASE_DSS_TEST_OBJECTS += $(addprefix $(PLATFORM_OBJDIR)/dssgenerated/, $(GTRACK_USECASE_DSS_TEST_SOURCES_GEN:.c=.$(C66_OBJ_EXT)))

###################################################################################
# Build Unit Test:
###################################################################################
gtrackTestDss: C66_CFLAGS += --define=GTRACK_$(MMWAVE_SDK_LIB_BUILD_OPTION)
gtrackTestDss: buildDirectories dssbuildDirectories $(GTRACK_USECASE_DSS_TEST_OBJECTS)
	$(C66_LD) $(C66_LDFLAGS) $(GTRACK_USECASE_DSS_TEST_LOC_LIBS) $(GTRACK_USECASE_DSS_TEST_STD_LIBS) 	\
   	--map_file=$(GTRACK_USECASE_DSS_TEST_MAP) 		\
	$(GTRACK_USECASE_DSS_TEST_OBJECTS) $(PLATFORM_C66X_LINK_CMD)	\
	$(GTRACK_USECASE_DSS_TEST_APP_CMD) -o $(GTRACK_USECASE_DSS_TEST_OUT)
	@echo '******************************************************************************'
	@echo 'Built the GTRACK $(MMWAVE_SDK_LIB_BUILD_OPTION) DSS Unit Test '
	@echo '******************************************************************************'

###################################################################################
# Cleanup Unit Test:
###################################################################################
gtrackTestDssClean:
	@echo 'Cleaning the GTRACK $(MMWAVE_SDK_LIB_BUILD_OPTION) DSS Unit Test objects'
	@$(DEL) $(GTRACK_USECASE_DSS_TEST_OBJECTS) $(GTRACK_USECASE_DSS_TEST_OUT) $(GTRACK_USECASE_DSS_TEST_BIN)
	@$(DEL) $(GTRACK_USECASE_DSS_TEST_MAP) $(GTRACK_USECASE_DSS_TEST_DEPENDS) $(GTRACK_USECASE_DSS_TEST_DEPENDS_GEN)
	@$(DEL) $(PLATFORM_OBJDIR)

###################################################################################
# Dependency handling
###################################################################################
-include $(GTRACK_USECASE_DSS_TEST_DEPENDS) $(GTRACK_USECASE_DSS_TEST_DEPENDS_GEN)

