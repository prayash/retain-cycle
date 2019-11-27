//
//  ViewController.swift
//  RetainCycle
//
//  Created by Prayash Thapa on 11/26/19.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemOrange

        let button = UIBarButtonItem(title: "Show", style: .plain, target: self, action: #selector(onShow))
        navigationItem.rightBarButtonItem = button
    }

    @objc func onShow() {
        navigationController?.pushViewController(IndigoController(), animated: true)
    }
}

class IndigoController: ViewController {
    let service = Service()
    var dummyClosure: ((String) -> ())?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemIndigo

        // Assigning this controller to the service will create a strong ref
        // Unless the service specifies its `controller` property as weak!
        service.controller = self

        // Beware! This closure captures the self as a strong reference unless
        // explicitly stated otherwise
        dummyClosure = { [weak self] arg in
            self?.alert()
        }

        NetworkingService.sharedInstance.simulateDataFetch { [weak self] data, error in
            if let _ = error {
                return
            }

            // Will produce a retain cycle. Use [weak self] modifier.
            self?.alert()
        }

        let name = NSNotification.Name(rawValue: "alertNotification")
        NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [unowned self] _ in

            // Without weak or unowned modifier, NotificationCenter will capture
            // this self reference as a strong reference.
            self.alert()
        }
    }

    func alert() {
        let alertController = UIAlertController(title: "Alert!", message: "Boo!", preferredStyle: .alert)

        present(alertController, animated: true, completion: nil)
    }

    // If this doesn't get called and print to the console, we have memory issues.
    deinit {
        print("IndigoController: Discarding memory.")
    }
}

class Service {
    // Without the weak modifier, this will create a retain cycle!
    weak var controller: IndigoController?
}

class NetworkingService {
    static let sharedInstance = NetworkingService()

    // We use an @escaping closure here because the completion handler is
    // actually invoked after the function returns. This is because URLSession.dataTask
    // is an async operation, so we mark the argument closure as @escaping to make
    // the compiler happy.
    func simulateDataFetch(completion: @escaping (Data?, Error?) -> ()) -> Void {
        guard let url = URL(string: "https://google.com") else {
            return
        }

        URLSession.shared.dataTask(with: url) { (data, response, error) in
            completion(nil, nil)
        }
    }
}
