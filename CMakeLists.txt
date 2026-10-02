cmake_minimum_required(VERSION 3.21)

project(
        RLOSDashboard
        VERSION 0.1
        LANGUAGES CXX
)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(
        Qt6 REQUIRED
        COMPONENTS
        Core
        Gui
        Qml
        Quick
        Network
)

qt_standard_project_setup()

set(
        QT_USE_RISKY_DSYM_ARCHIVING_WORKAROUND
        ON
)

qt_add_executable(
        RLOSDashboard

        src/main.cpp
        src/ApiClient.cpp

        inc/ApiClient.h
)

target_include_directories(
        RLOSDashboard

        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/inc
)

qt_add_qml_module(
        RLOSDashboard

        URI RLOS.Dashboard
        VERSION 1.0

        QML_FILES
        Main.qml

        pages/TestsPage.qml
        pages/TestDetailsPage.qml
        pages/PlotDetailPage.qml
        pages/PlotCard.qml
)

# ---------------------------------------------------------
# iOS app configuration
# ---------------------------------------------------------

if(IOS)

    set(APP_ASSET_CATALOG
            "${CMAKE_CURRENT_SOURCE_DIR}/assets/Assets.xcassets"
    )

    target_sources(
            RLOSDashboard
            PRIVATE
            ${APP_ASSET_CATALOG}
    )

    set_source_files_properties(
            ${APP_ASSET_CATALOG}
            PROPERTIES
            MACOSX_PACKAGE_LOCATION Resources
    )

    set_target_properties(
            RLOSDashboard
            PROPERTIES

            MACOSX_BUNDLE TRUE

            MACOSX_BUNDLE_GUI_IDENTIFIER
            "inAirAviation.RLOSDashboard"

            XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER
            "inAirAviation.RLOSDashboard"

            XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME
            "AppIcon"
    )

endif()

target_link_libraries(
        RLOSDashboard

        PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::Network
)