cmake_minimum_required(VERSION 3.21)

project(Tanaw
    VERSION 1.0.0
    DESCRIPTION "Desktop IPTV playlist and player"
    LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.8 REQUIRED COMPONENTS
    Core
    Gui
    Multimedia
    Network
    Qml
    Quick
    QuickControls2
)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(Tanaw
    src/main.cpp
    src/channelmodel.cpp
    src/channelmodel.h
    src/tanawcontroller.cpp
    src/tanawcontroller.h
)

qt_add_qml_module(Tanaw
    URI Tanaw
    VERSION 1.0
    QML_FILES
        qml/main.qml
        RESOURCES src/resource.rc qml/favicon.ico
)

# Windows Icon Configuration
if(WIN32)
    set(APP_ICON_RESOURCE_WINDOWS "src/resource.rc")

    # Append the .rc file directly into your target sources
    target_sources(Tanaw PRIVATE ${APP_ICON_RESOURCE_WINDOWS})
endif()

# Disables AVX/AVX2 emit

# MSVC
if(MSVC)
    # Ensure no modern vector extensions are injected
    # MSVC targets SSE2 by default on x64, which is safe for Box64.
    # If your project explicitly sets /arch:AVX, we can override or strip it:
    string(REPLACE "/arch:AVX2" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    string(REPLACE "/arch:AVX" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
    
    # Or, explicitly force standard x64 compilation behavior
    add_compile_options(/arch:SSE2) 
endif()

# MINGW / GCC / Clang
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    # Explicitly turn off AVX, AVX2, and FMA
    add_compile_options(
        -mno-avx
        -mno-avx2
        -mno-fma
        -mno-avx512f
    )
    
    # Strictly avoid "-march=native", which would optimize for your host CPU!
    # Instead, force a generic or standard x86-64 target architecture
    add_compile_options(-march=x86-64)
endif()


target_link_libraries(Tanaw PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Multimedia
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

set_target_properties(Tanaw PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
)

include(GNUInstallDirs)
install(TARGETS Tanaw
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)