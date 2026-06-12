# (C) Copyright 2011- ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation
# nor does it submit to any jurisdiction.

# - Try to find MKL
# Once done this will define
#
#  MKL_FOUND         - system has Intel MKL
#  MKL_INCLUDE_DIRS  - the MKL include directories
#  MKL_LIBRARIES     - link these to use MKL
#
# The following paths will be searched with priority if set in CMake or env
#
#  MKLROOT           - root directory of the MKL installation
#  MKL_PATH          - root directory of the MKL installation
#  MKL_ROOT          - root directory of the MKL installation
#  MKL_INTERFACE_FULL - interface library suffix/name (default: intel_lp64 on x86_64)
#  MKL_THREADING     - threading library name suffix (default: sequential,
#                      or intel_thread when MKL_PARALLEL=ON)

option( MKL_PARALLEL "if mkl shoudl be parallel" OFF )

if( NOT DEFINED MKL_INTERFACE_FULL )
  if( CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" )
    set( MKL_INTERFACE_FULL intel_lp64 CACHE STRING "MKL interface library suffix/name" )
  else()
    set( MKL_INTERFACE_FULL intel CACHE STRING "MKL interface library suffix/name" )
  endif()
endif()

if( NOT DEFINED MKL_THREADING )
  if( MKL_PARALLEL )
    set( MKL_THREADING intel_thread CACHE STRING "MKL threading library suffix/name" )
  else()
    set( MKL_THREADING sequential CACHE STRING "MKL threading library suffix/name" )
  endif()
endif()

set_property( CACHE MKL_THREADING PROPERTY STRINGS sequential intel_thread gnu_thread tbb_thread )

find_package( Threads )

# Search with priority for MKLROOT, MKL_PATH and MKL_ROOT if set in CMake or env
find_path(MKL_INCLUDE_DIR mkl.h
          PATHS ${MKLROOT} ${MKL_PATH} ${MKL_ROOT} $ENV{MKLROOT} $ENV{MKL_PATH} $ENV{MKL_ROOT}
          PATH_SUFFIXES include NO_DEFAULT_PATH)

find_path(MKL_INCLUDE_DIR mkl.h
          PATH_SUFFIXES include)

if( MKL_INCLUDE_DIR ) # use include dir to find libs

  set( MKL_INCLUDE_DIRS ${MKL_INCLUDE_DIR} )

  if( CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" )
    set( __pathsuffix "lib/intel64")
  else()
    set( __pathsuffix "lib/ia32")
  endif()

  find_library( MKL_LIB_INTERFACE
                PATHS ${MKLROOT} ${MKL_PATH} ${MKL_ROOT} $ENV{MKLROOT} $ENV{MKL_PATH} $ENV{MKL_ROOT}
                PATH_SUFFIXES lib ${__pathsuffix}
                NAMES mkl_${MKL_INTERFACE_FULL} )

  find_library( MKL_LIB_THREADING
                PATHS ${MKLROOT} ${MKL_PATH} ${MKL_ROOT} $ENV{MKLROOT} $ENV{MKL_PATH} $ENV{MKL_ROOT}
                PATH_SUFFIXES lib ${__pathsuffix}
                NAMES mkl_${MKL_THREADING} )

  find_library( MKL_LIB_CORE
                PATHS ${MKLROOT} ${MKL_PATH} ${MKL_ROOT} $ENV{MKLROOT} $ENV{MKL_PATH} $ENV{MKL_ROOT}
                PATH_SUFFIXES lib ${__pathsuffix}
                NAMES mkl_core )

  unset( MKL_RUNTIME_LIBRARIES )

  if( MKL_THREADING STREQUAL "intel_thread" )
    find_library( MKL_LIB_IOMP5
                  PATHS ${MKLROOT} ${MKL_PATH} ${MKL_ROOT} $ENV{MKLROOT} $ENV{MKL_PATH} $ENV{MKL_ROOT}
                  PATH_SUFFIXES lib ${__pathsuffix}
                  NAMES iomp5 )
    list( APPEND MKL_RUNTIME_LIBRARIES ${MKL_LIB_IOMP5} ${CMAKE_THREAD_LIBS_INIT} )
  elseif( MKL_THREADING STREQUAL "gnu_thread" )
    find_library( MKL_LIB_GOMP NAMES gomp )
    if( MKL_LIB_GOMP )
      list( APPEND MKL_RUNTIME_LIBRARIES ${MKL_LIB_GOMP} )
    else()
      list( APPEND MKL_RUNTIME_LIBRARIES gomp )
    endif()
    list( APPEND MKL_RUNTIME_LIBRARIES ${CMAKE_THREAD_LIBS_INIT} m ${CMAKE_DL_LIBS} )
  elseif( MKL_THREADING STREQUAL "tbb_thread" )
    find_library( MKL_LIB_TBB NAMES tbb )
    list( APPEND MKL_RUNTIME_LIBRARIES ${MKL_LIB_TBB} ${CMAKE_THREAD_LIBS_INIT} )
  else()
    list( APPEND MKL_RUNTIME_LIBRARIES ${CMAKE_THREAD_LIBS_INIT} )
  endif()

  if( MKL_LIB_INTERFACE AND MKL_LIB_THREADING AND MKL_LIB_CORE )
    set( MKL_LIBRARIES ${MKL_LIB_INTERFACE} ${MKL_LIB_THREADING} ${MKL_LIB_CORE} ${MKL_RUNTIME_LIBRARIES} )
    list( REMOVE_DUPLICATES MKL_LIBRARIES )
  endif()

endif()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args( MKL DEFAULT_MSG
                                   MKL_LIBRARIES MKL_INCLUDE_DIRS )

mark_as_advanced( MKL_INCLUDE_DIR MKL_LIB_LAPACK MKL_LIB_INTERFACE MKL_LIB_THREADING MKL_LIB_CORE )
