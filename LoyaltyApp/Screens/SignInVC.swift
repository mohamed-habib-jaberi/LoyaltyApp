//
//  SignInVC.swift
//  LoyaltyApp
//
//  Created by eidd5180 on 18/02/2021.
//

import UIKit
import LoyaltyAPIClient
import RxSwift
import RxCocoa

protocol SignInVCDelegate: AnyObject {
    func signInViewControllerDidSignInWithSuccess(_ controller: SignInVC)
    func signInViewControllerDidFailedToSignIn(_ controller: SignInVC, credential: String, error: Error)
}

final class SignInVC: UIViewController {
    // MARK: - iVar | UIKit
    @IBOutlet private(set) weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private(set) weak var passwordTextField: UITextField!
    @IBOutlet private(set) weak var emailTextField: UITextField!
    @IBOutlet private(set) weak var signInButton: UIButton!

    // MARK: - iVar | Rx
    private let disposeBag = DisposeBag()
    private var viewModel: SignInViewModel?

    // MARK: - iVar | API
    weak var delegate: SignInVCDelegate?

    // MARK: - Init
    init() {
        super.init(nibName: "SignInVC", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        let viewModel = SignInViewModel(dependencies: DI())

        /// Binds Inputs
        self.emailTextField.rx.text.bind(to: viewModel.emailInput).disposed(by: self.disposeBag)
        self.passwordTextField.rx.text.bind(to: viewModel.passInput).disposed(by: self.disposeBag)
        self.signInButton.rx.controlEvent(.touchUpInside).bind(to: viewModel.buttonTriggered).disposed(by: self.disposeBag)

        /// Binds Outputs
        // Loading indicator
        viewModel.isActivityIndicatorAnimating.drive(activityIndicator.rx.isAnimating).disposed(by: self.disposeBag)

        // Locking input
        viewModel.inputEnabled.drive(passwordTextField.rx.isEnabled).disposed(by: self.disposeBag)
        viewModel.inputEnabled.drive(emailTextField.rx.isEnabled).disposed(by: self.disposeBag)
        viewModel.inputEnabled.drive(signInButton.rx.isEnabled).disposed(by: self.disposeBag)

        // Sign in result
        viewModel.signInResult.emit(onNext: { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .failure(let credentialError):
                self.delegate?.signInViewControllerDidFailedToSignIn(self, credential: credentialError.email, error: credentialError.error)
            case .success(_):
                self.delegate?.signInViewControllerDidSignInWithSuccess(self)
            }
        }).disposed(by: self.disposeBag)
        self.viewModel = viewModel
    }
}



