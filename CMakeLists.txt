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
    QuickDialogs2
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

target_link_libraries(Tanaw PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Multimedia
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::QuickDialogs2
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