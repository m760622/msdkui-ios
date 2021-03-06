//
// Copyright (C) 2017-2019 HERE Europe B.V.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import MSDKUI
@testable import MSDKUI_Demo
import NMAKit
import UIKit
import XCTest

final class GuidanceViewControllerTests: XCTestCase {

    /// The object under test.
    private var viewControllerUnderTest: GuidanceViewController?

    /// The mock map route handler used to verify expectations.
    private var mockMapRouteHandler = MapRouteHandlerMock()

    /// The mock notification center used to verify expectations.
    private var mockNotificationCenter = NotificationCenterObservingMock()

    /// The real `rootViewController` is replaced with `viewControllerUnderTest`.
    private let originalRootViewController = UIApplication.shared.keyWindow?.rootViewController

    override func setUp() {
        super.setUp()

        // Create the viewControllerUnderTest object
        viewControllerUnderTest = UIStoryboard.instantiateFromStoryboard(named: .driveNavigation) as GuidanceViewController

        // Set mocked location authorization provider
        viewControllerUnderTest?.locationAuthorizationStatusProvider = { .authorizedAlways }

        // Set mock notification center
        viewControllerUnderTest?.notificationCenter = mockNotificationCenter

        // Set mock idle timer disabler
        viewControllerUnderTest?.idleTimerDisabler = IdleTimerDisablerMock()

        // Set mock map route handler
        mockMapRouteHandler.stubMapRoute(toReturn: MockUtils.mockMapRoute())
        viewControllerUnderTest?.mapRouteHandler = mockMapRouteHandler

        // Set mock route
        viewControllerUnderTest?.route = MockUtils.mockRoute()

        // In order to get the orientation changes, set the `viewControllerUnderTest` as the `rootViewController`
        UIApplication.shared.keyWindow?.rootViewController = viewControllerUnderTest

        // Load the view hierarchy
        viewControllerUnderTest?.loadViewIfNeeded()
    }

    override func tearDown() {
        // The map view rendering is problematic at the end of tests
        viewControllerUnderTest?.mapView.isRenderAllowed = false

        // Done
        viewControllerUnderTest?.stopNavigation()

        // The default orientation
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKeyPath: #keyPath(UIDevice.orientation))

        // Restore
        UIApplication.shared.keyWindow?.rootViewController = originalRootViewController

        super.tearDown()
    }

    // MARK: - Tests

    /// Tests the status bar visibility.
    func testStatusBar() throws {
        XCTAssertFalse(try require(viewControllerUnderTest?.prefersStatusBarHidden), "It hides the status bar")
    }

    /// Checks the GuidanceViewController.preferredStatusBarStyle variable.
    func testStatusBarStyle() {
        XCTAssertEqual(viewControllerUnderTest?.preferredStatusBarStyle, .lightContent,
                       "Not the expected statusbar style!")
    }

    /// Checks if the Next Maneuver View exists and is configured.
    func testNextManeuverView() throws {
        XCTAssertNotNil(viewControllerUnderTest?.nextManeuverView, "It has the next maneuver view")
        XCTAssertTrue(try require(viewControllerUnderTest?.nextManeuverView.isHidden), "It has the next maneuver view hidden by default")
        XCTAssertEqual(try require(viewControllerUnderTest?.nextManeuverView.layoutMargins),
                       UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20),
                       "It has the next maneuver view layout margins correctly set")
    }

    /// Checks if the Speed View exists and is configured.
    func testSpeedView() throws {
        XCTAssertNotNil(viewControllerUnderTest?.currentSpeedView, "It has the speed view")

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.textAlignment, .center,
                       "It has a speed view with centered content")

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.backgroundColor, .colorBackgroundBrand,
                       "It has a speed view with correct background color")

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.speedValueTextColor, .colorForegroundLight,
                       "It has a speed view with correct speed value color")

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.speedUnitTextColor, .colorForegroundLight,
                       "It has a speed view with correct speed unit color")

        XCTAssertTrue(try require(viewControllerUnderTest?.currentSpeedView.isHidden),
                      "It hides the current speed view")

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.layer.cornerRadius, (try require(viewControllerUnderTest?.currentSpeedView.bounds.height)) / 2,
                       "It has a circular speed view")
    }

    /// Checks if the Speed Limit View exists and is configured.
    func testSpeedLimitView() throws {
        XCTAssertNotNil(viewControllerUnderTest?.speedLimitView, "It has the speed limit view")

        XCTAssertEqual(viewControllerUnderTest?.speedLimitView.layer.cornerRadius, (try require(viewControllerUnderTest?.speedLimitView.bounds.height)) / 2,
                       "It has a circular speed limit view")

        XCTAssertEqual(viewControllerUnderTest?.speedLimitView.layer.borderWidth, 4,
                       "It has a circular speed limit view with border")

        XCTAssertEqual(viewControllerUnderTest?.speedLimitView.layer.borderColor, UIColor.red.cgColor,
                       "It has a circular speed limit view with colored border")
    }

    /// Tests if the Map Overlay View exists and is configured.
    func testMapOverlayView() {
        XCTAssertNotNil(viewControllerUnderTest?.mapOverlayView, "It has the map overlay view")
        XCTAssertEqual(viewControllerUnderTest?.mapOverlayView.backgroundColor, .black, "It has the correct color")
        XCTAssertEqual(viewControllerUnderTest?.mapOverlayView.alpha, 0.0, "It has the correct alpha")
    }

    /// Checks if the Speed Monitor exists.
    func testSpeedMonitor() {
        XCTAssertNotNil(viewControllerUnderTest?.speedMonitor, "It has the speed monitor")
    }

    /// Tests the Dashboard Overlay (only visible on iPhone X)
    func testDashboardOverlay() {
        // Does it have the correct color?
        XCTAssertEqual(viewControllerUnderTest?.dashboardOverlayView.backgroundColor, .colorBackgroundDark, "It has the correct color")

        // Does it have the correct number of layout constraints?
        let constraints = viewControllerUnderTest?.view.constraints.filter { constraint in
            constraint.firstItem === viewControllerUnderTest?.dashboardOverlayView || constraint.secondItem === viewControllerUnderTest?.dashboardOverlayView
        }

        XCTAssertEqual(constraints?.count, 4, "It has the correct number of layout constraints")

        // Does it have the correct leading constraint?
        let leadingConstraint = constraints?.first { constraint in
            constraint.firstItem === viewControllerUnderTest?.dashboardOverlayView && constraint.firstAttribute == .leading
        }

        XCTAssert(leadingConstraint?.secondItem === viewControllerUnderTest?.view, "It has the correct leading constraint")
        XCTAssertEqual(leadingConstraint?.constant, 0, "It has the correct leading constraint constant")

        // Does it have the correct top constraint?
        let topConstraint = constraints?.first { constraint in
            constraint.firstItem === viewControllerUnderTest?.dashboardOverlayView && constraint.firstAttribute == .top
        }

        XCTAssert(topConstraint?.secondItem === viewControllerUnderTest?.bottomLayoutGuide, "It has the correct top constraint (the bottom safe layout guide)")
        XCTAssertEqual(topConstraint?.constant, 0, "It has the correct top constraint constant")

        // Does it have the correct bottom constraint?
        let bottomConstraint = constraints?.first { constraint in
            constraint.secondItem === viewControllerUnderTest?.dashboardOverlayView && constraint.secondAttribute == .bottom
        }

        XCTAssert(bottomConstraint?.firstItem === viewControllerUnderTest?.view, "It has the correct bottom constraint (the superview's bottom)")
        XCTAssertEqual(bottomConstraint?.constant, 0, "It has the correct bottom constraint constant")

        // Does it have the correct trailing constraint?
        let trailingConstraint = constraints?.first { constraint in
            constraint.secondItem === viewControllerUnderTest?.dashboardOverlayView && constraint.secondAttribute == .trailing
        }

        XCTAssert(trailingConstraint?.firstItem === viewControllerUnderTest?.view, "It has the correct trailing constraint")
        XCTAssertEqual(trailingConstraint?.constant, 0, "It has the correct trailing constraint constant")
    }

    /// Tests `MapRouteHandler` handles the correct objects.
    func testMapRouteHandler() {
        XCTAssertEqual(mockMapRouteHandler.lastRoute, viewControllerUnderTest?.route, "It handles correct route")
        XCTAssertEqual(mockMapRouteHandler.lastMapView, viewControllerUnderTest?.mapView, "It handles correct map view")
        XCTAssertEqual(mockMapRouteHandler.lastMapRoute, viewControllerUnderTest?.mapRoute, "It handles correct map route")
    }

    // MARK: - GuidanceManeuverMonitorDelegate

    /// Tests the behavior when `GuidanceViewController.guidanceManeuverMonitor(_:didUpdateData:)` returns data.
    func testWhenGuidanceManeuverMonitorDidUpdateDataIsTriggeredWithData() throws {
        let monitor = try require(viewControllerUnderTest?.maneuverMonitor)
        let maneuverData = GuidanceManeuverData()

        viewControllerUnderTest?.guidanceManeuverMonitor(monitor, didUpdateData: maneuverData)

        // Is the data passed?
        XCTAssertEqual(viewControllerUnderTest?.maneuverView.state, .data(maneuverData), "It has the correct data")
    }

    /// Tests the behavior when `GuidanceViewController.guidanceManeuverMonitor(_:didUpdateData:)` doesn't return data.
    func testWhenGuidanceManeuverMonitorDidUpdateDataIsTriggeredWithNil() throws {
        let monitor = try require(viewControllerUnderTest?.maneuverMonitor)

        viewControllerUnderTest?.guidanceManeuverMonitor(monitor, didUpdateData: nil)

        // Is the data passed?
        XCTAssertEqual(viewControllerUnderTest?.maneuverView.state, .updating, "It has the correct state")
    }

    /// Tests the behavior when `GuidanceViewController.guidanceManeuverMonitorDidReachDestination(_:)` is triggered.
    func testWhenGuidanceManeuverMonitorDidReachDestinationIsTriggered() throws {
        let monitor = try require(viewControllerUnderTest?.maneuverMonitor)

        viewControllerUnderTest?.guidanceManeuverMonitorDidReachDestination(monitor)

        // Are the Info2 labels highlighted?
        viewControllerUnderTest?.maneuverView.info2Labels.forEach {
            XCTAssertEqual($0.textColor, .colorAccentLight,
                           "Maneuver view info2 labels not highlighted!")
        }

        // Is the idle timer enabled?
        let idleTimerDisabler = try require(viewControllerUnderTest?.idleTimerDisabler)
        XCTAssertFalse(idleTimerDisabler.isIdleTimerDisabled, "Idle timer is enabled when reached the destination")
    }

    // MARK: - GuidanceCurrentStreetNameMonitorDelegate

    /// Tests configuration of current street label with current street view model when current street name changes to a valid name.
    func testGuidanceCurrentStreetNameMonitorDidUpdateCurrentStreetNameWithContent() throws {
        let viewControllerUnderTest = try require(self.viewControllerUnderTest)

        let expectedCurrentStreetName = "Invalidenstraße"
        viewControllerUnderTest.guidanceCurrentStreetNameMonitor(viewControllerUnderTest.guidanceCurrentStreetNameMonitor,
                                                                 didUpdateCurrentStreetName: expectedCurrentStreetName)

        // Label
        XCTAssertFalse(viewControllerUnderTest.currentStreetLabel.isHidden, "It is visible")
        XCTAssertEqual(viewControllerUnderTest.currentStreetLabel.text, expectedCurrentStreetName, "It has correct text")
        XCTAssertEqual(viewControllerUnderTest.currentStreetLabel.backgroundColor, .colorPositive, "It has correct background color")
    }

    /// Tests configuration of current street label with current street view model when current street
    /// name changes to a empty name.
    func testGuidanceCurrentStreetNameMonitorDidUpdateCurrentStreetNameWithoutContent() throws {
        let viewControllerUnderTest = try require(self.viewControllerUnderTest)

        [nil, "", " "].forEach {
            // Initially label should be visible to verify if it will be hidden
            viewControllerUnderTest.currentStreetLabel.isHidden = false

            viewControllerUnderTest.guidanceCurrentStreetNameMonitor(viewControllerUnderTest.guidanceCurrentStreetNameMonitor,
                                                                     didUpdateCurrentStreetName: $0)

            // Label
            XCTAssertTrue(viewControllerUnderTest.currentStreetLabel.isHidden, "It is hidden")
        }
    }

    // MARK: - Routing

    /// Tests failed rerouting for empty and nil routes.
    func testFailedRerouting() throws {
        try failedRerouting(with: MockUtils.mockRouteResult(with: []))
        try failedRerouting(with: MockUtils.mockRouteResult(with: nil))
    }

    // MARK: - IdleTimerDisabler

    /// Tests when there is no navigation, the idle timer is enabled.
    func testWhenNavigationIsNotStartedIdleTimerIsEnabled() throws {
        // Note that due to the mock route, navigation is started in GuidanceViewControllerT.viewDidLoad()
        // So, stop the navigation and clear the route to prevent starting the navigation
        viewControllerUnderTest?.stopNavigation()
        viewControllerUnderTest?.route = nil
        viewControllerUnderTest?.viewDidLoad()

        let idleTimerDisabler = try require(viewControllerUnderTest?.idleTimerDisabler)
        XCTAssertFalse(idleTimerDisabler.isIdleTimerDisabled, "Idle timer is enabled by default")
    }

    /// Tests when a navigation is started, the idle timer is disabled.
    func testWhenNavigationIsStartedIdleTimerIsDisabled() throws {
        // Note that due to the mock route, navigation is started in GuidanceViewControllerT.viewDidLoad()
        let idleTimerDisabler = try require(viewControllerUnderTest?.idleTimerDisabler)
        XCTAssertTrue(idleTimerDisabler.isIdleTimerDisabled, "Idle timer is disabled when the guidance starts")
    }

    /// Tests when a navigation is stopped, the idle timer is disabled.
    func testWhenNavigatioIsStoppedIdleTimerIsEnabled() throws {
        viewControllerUnderTest?.stopNavigation()

        let idleTimerDisabler = try require(viewControllerUnderTest?.idleTimerDisabler)
        XCTAssertFalse(idleTimerDisabler.isIdleTimerDisabled, "Idle time is enabled when the guidance stops")
    }

    // MARK: - GuidanceSpeedMonitorDelegate

    /// Tests when `.guidanceSpeedMonitor(_:didUpdateCurrentSpeed:isSpeeding:speedLimit:)` is triggered with valid speed.
    func testWhenGuidanceSpeedMonitorDidUpdateCurrentSpeedIsSpeedingSpeedLimitIsTriggeredWithValidSpeed() throws {
        let monitor = try require(viewControllerUnderTest?.speedMonitor)
        let speed = Measurement<UnitSpeed>(value: 10, unit: .metersPerSecond)
        let speedLimit = Measurement<UnitSpeed>(value: 20, unit: .metersPerSecond)

        viewControllerUnderTest?.guidanceSpeedMonitor(monitor, didUpdateCurrentSpeed: speed, isSpeeding: false, speedLimit: speedLimit)

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.speed, speed,
                       "It shows a view configured with the correct speed")

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.backgroundColor, .colorBackgroundBrand,
                       "It shows the speed view with correct background color")

        XCTAssertFalse(try require(viewControllerUnderTest?.speedLimitView.isHidden), "It shows the speed limit view")
    }

    /// Tests when `.guidanceSpeedMonitor(_:didUpdateCurrentSpeed:isSpeeding:speedLimit:)` is triggered with speeding speed.
    func testWhenGuidanceSpeedMonitorDidUpdateCurrentSpeedIsSpeedingSpeedLimitIsTriggeredWithSpeedingSpeed() throws {
        let monitor = try require(viewControllerUnderTest?.speedMonitor)
        let speed = Measurement<UnitSpeed>(value: 20, unit: .metersPerSecond)
        let speedLimit = Measurement<UnitSpeed>(value: 10, unit: .metersPerSecond)

        viewControllerUnderTest?.guidanceSpeedMonitor(monitor, didUpdateCurrentSpeed: speed, isSpeeding: true, speedLimit: speedLimit)

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.speed, speed,
                       "It shows a view configured with the correct speed")

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.backgroundColor, .colorNegative,
                       "It shows the speed view with correct background color")

        XCTAssertFalse(try require(viewControllerUnderTest?.speedLimitView.isHidden), "It shows the speed limit view")
    }

    /// Tests when `.guidanceSpeedMonitor(_:didUpdateCurrentSpeed:isSpeeding:speedLimit:)` is triggered without speed limit.
    func testWhenGuidanceSpeedMonitorDidUpdateCurrentSpeedWithoutSpeedLimit() throws {
        let monitor = try require(viewControllerUnderTest?.speedMonitor)
        let speed = Measurement<UnitSpeed>(value: 10, unit: .metersPerSecond)

        viewControllerUnderTest?.guidanceSpeedMonitor(monitor, didUpdateCurrentSpeed: speed, isSpeeding: false, speedLimit: nil)

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.speed, speed,
                       "It shows a view configured with the correct speed")

        XCTAssertEqual(viewControllerUnderTest?.currentSpeedView.backgroundColor, .colorBackgroundBrand,
                       "It shows the speed view with correct background color")

        XCTAssertTrue(try require(viewControllerUnderTest?.speedLimitView.isHidden), "It hides the speed limit view")
    }

    // MARK: - GuidanceDashboardViewControllerDelegate

    /// Tests when `.guidanceDashboardViewController(_:didSelectItem:)` is triggered with `.about` item.
    func testGuidanceDashboardViewControllerDidSelectItemAbout() throws {
        let viewControllerUnderTest = try require(self.viewControllerUnderTest)

        // Sets the testing expectation
        let predicate = NSPredicate(format: "presentedViewController != nil")
        expectation(for: predicate, evaluatedWith: viewControllerUnderTest)

        viewControllerUnderTest.guidanceDashboardViewController(GuidanceDashboardViewController(), didSelectItem: .about)

        // Sets the timeout for the expectation
        waitForExpectations(timeout: 5)

        // Confirms if the view controller under tests presents the about view controller
        XCTAssertNotNil(viewControllerUnderTest.presentedViewController as? AboutViewController, "It presents the about view controller")
    }

    /// Tests when `.guidanceDashboardViewController(_:didSelectItem:)` is triggered with `.settings` item.
    func testGuidanceDashboardViewControllerDidSelectItemSettings() throws {
        let viewControllerUnderTest = try require(self.viewControllerUnderTest)

        // Sets the testing expectation
        let predicate = NSPredicate(format: "presentedViewController == nil")
        expectation(for: predicate, evaluatedWith: viewControllerUnderTest)

        viewControllerUnderTest.guidanceDashboardViewController(GuidanceDashboardViewController(), didSelectItem: .settings)

        // Sets the timeout for the expectation
        waitForExpectations(timeout: 5)

        // Confirms if it the screen stays on the view controller under test
        XCTAssertNil(viewControllerUnderTest.presentedViewController, "It doesn't present another view controller")
    }

    /// Tests when `.guidanceDashboardViewControllerDidTapView(_:)` is triggered once.
    func testWhenGuidanceDashboardViewControllerDidTapViewIsTriggeredOnce() throws {
        var lastDuration: TimeInterval?
        var lastAnimation: (() -> Void)?

        // Grabs the parameters passed to the view animator
        viewControllerUnderTest?.viewAnimator = { duration, animation in
            lastDuration = duration
            lastAnimation = animation
        }

        // Triggers the delegate method
        viewControllerUnderTest?.guidanceDashboardViewControllerDidTapView(GuidanceDashboardViewController())

        // Checks if the animation has the correct duration
        XCTAssertEqual(lastDuration, 0.3, "It opens the dashboard with the correct duration")

        // Triggers the animation completion block (which animates the height change)
        lastAnimation?()

        // Checks if the dashboard has the correct height after the animation
        XCTAssertEqual(viewControllerUnderTest?.dashboardVisibleHeightConstraint.constant, 197,
                       "It opens the dashboard with correct height")

        // Checks if the map overlay view has the correct alpha
        XCTAssertEqual(try require(viewControllerUnderTest?.mapOverlayView.alpha), 0.5, accuracy: 0.01,
                       "It sets the correct map overlay view alpha")
    }

    /// Tests when `.guidanceDashboardViewControllerDidTapView(_:)` is triggered twice.
    func testWhenGuidanceDashboardViewControllerDidTapViewIsTriggeredTwice() {
        var lastAnimation: (() -> Void)?

        // Grabs the animation parameter passed to the view animator
        viewControllerUnderTest?.viewAnimator = { _, animation in
            lastAnimation = animation
        }

        // Triggers the delegate method
        viewControllerUnderTest?.guidanceDashboardViewControllerDidTapView(GuidanceDashboardViewController())

        // Triggers the animation completion block (which animates the height change)
        lastAnimation?()

        // Checks if the dashboard has the correct height after the animation
        XCTAssertEqual(viewControllerUnderTest?.dashboardVisibleHeightConstraint.constant, 197,
                       "It opens the dashboard with correct height")

        // Triggers the delegate method (again)
        viewControllerUnderTest?.guidanceDashboardViewControllerDidTapView(GuidanceDashboardViewController())

        // Triggers the animation completion block (again)
        lastAnimation?()

        // Checks if the dashboard has the correct height after the animation
        XCTAssertEqual(viewControllerUnderTest?.dashboardVisibleHeightConstraint.constant, 84,
                       "It collapses the dashboard with correct height")

        // Checks if the map overlay view has the correct alpha
        XCTAssertEqual(viewControllerUnderTest?.mapOverlayView.alpha, 0.0, "It sets the correct map overlay view alpha")
    }

    /// Tests when `.guidanceDashboardViewControllerDidTapStopNavigation(_:)` is triggered.
    func testWhenGuidanceDashboardViewControllerDidTapStopNavigationIsTriggered() throws {
        viewControllerUnderTest?.startNavigation()

        viewControllerUnderTest?.guidanceDashboardViewControllerDidTapStopNavigation(GuidanceDashboardViewController())

        XCTAssertEqual(NMANavigationManager.sharedInstance().navigationState, .idle, "It stops the navigation")
    }

    // MARK: - Map Overlay

    /// Tests the behavior when the map overlay view is tapped (gesture began).
    func testWhenMapOverlayViewIsTappedGestureBegan() {
        // Triggers the delegate method to open the dashboard
        viewControllerUnderTest?.guidanceDashboardViewControllerDidTapView(GuidanceDashboardViewController())

        // Check if the dashboard is open
        XCTAssertEqual(viewControllerUnderTest?.dashboardState, .open, "It opens the dashboard")

        // Taps the map overlay
        viewControllerUnderTest?.handleMapOverlayViewTap(MockUtils.mockTapGestureRecognizer(with: .began))

        // Checks if the dashboard is still open
        XCTAssertEqual(viewControllerUnderTest?.dashboardState, .open, "It doesn't close the dashboard")
    }

    /// Tests the behavior when the map overlay view is tapped (gesture ended).
    func testWhenMapOverlayViewIsTappedGestureEnded() {
        // Triggers the delegate method to open the dashboard
        viewControllerUnderTest?.guidanceDashboardViewControllerDidTapView(GuidanceDashboardViewController())

        // Check if the dashboard is open
        XCTAssertEqual(viewControllerUnderTest?.dashboardState, .open, "It opens the dashboard")

        // Taps the map overlay
        viewControllerUnderTest?.handleMapOverlayViewTap(MockUtils.mockTapGestureRecognizer(with: .ended))

        // Checks if the dashboard is collapsed
        XCTAssertEqual(viewControllerUnderTest?.dashboardState, .collapsed, "It closes the dashboard")
    }

    // MARK: - Private

    private func failedRerouting(with failingRouteResult: NMARouteResult) throws {
        let viewControllerUnderTest = try require(self.viewControllerUnderTest)
        let routeBefore = viewControllerUnderTest.route
        let mapRouteBefore = viewControllerUnderTest.mapRoute

        viewControllerUnderTest.navigationManager(NMANavigationManager.sharedInstance(), didUpdateRoute: failingRouteResult)

        XCTAssertEqual(viewControllerUnderTest.route, routeBefore, "Failed rerouting does not change the route")
        XCTAssertEqual(viewControllerUnderTest.mapRoute, mapRouteBefore, "Failed rerouting does not change the map route")
    }
}
