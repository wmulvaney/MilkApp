import SwiftUI
import UIKit

struct PageViewController<Page: View>: UIViewControllerRepresentable {
    var pages: [Page]
    @Binding var currentPage: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [UIPageViewController.OptionsKey.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        pageViewController.view.backgroundColor = .systemBackground // Change this line
        pageViewController.isDoubleSided = false
        
        // Set the initial page
        pageViewController.setViewControllers(
            [context.coordinator.controllers[currentPage]], 
            direction: .forward, 
            animated: false
        )
        
        return pageViewController
    }

    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        if let currentViewController = pageViewController.viewControllers?.first,
           let currentIndex = context.coordinator.controllers.firstIndex(of: currentViewController),
           currentIndex != currentPage {
            let direction: UIPageViewController.NavigationDirection = currentPage > currentIndex ? .forward : .reverse
            pageViewController.setViewControllers(
                [context.coordinator.controllers[currentPage]], 
                direction: direction, 
                animated: true
            )
        }
    }

    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController
        var controllers = [UIViewController]()

        init(_ pageViewController: PageViewController) {
            parent = pageViewController
            controllers = parent.pages.map { UIHostingController(rootView: $0) }
            controllers.forEach { 
                $0.view.backgroundColor = .systemBackground // Change this line
            }
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index == 0 { return nil }
            return controllers[index - 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let index = controllers.firstIndex(of: viewController) else { return nil }
            if index + 1 == controllers.count { return nil }
            return controllers[index + 1]
        }

        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let visibleViewController = pageViewController.viewControllers?.first,
               let index = controllers.firstIndex(of: visibleViewController) {
                parent.currentPage = index
            }
        }
    }
}
