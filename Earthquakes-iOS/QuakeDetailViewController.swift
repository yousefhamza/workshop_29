/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The UIKit version of the view which displays details of an earthquake selected from a list.
*/

import SwiftUI
import UIKit

final class QuakeDetailViewController: UIViewController {
    private let quake: Quake

    init(quake: Quake) {
        self.quake = quake
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let magnitudeLabel = UILabel()
        magnitudeLabel.text = quake.magnitude.formatted(.number.precision(.fractionLength(1)))
        magnitudeLabel.font = .preferredFont(forTextStyle: .title1).bold()
        magnitudeLabel.textColor = UIColor(quake.color)
        magnitudeLabel.textAlignment = .center
        magnitudeLabel.backgroundColor = .black
        magnitudeLabel.layer.cornerRadius = 8
        magnitudeLabel.layer.masksToBounds = true

        let placeLabel = UILabel()
        placeLabel.text = quake.place
        placeLabel.font = .preferredFont(forTextStyle: .title3).bold()
        placeLabel.textAlignment = .center
        placeLabel.numberOfLines = 0

        let timeLabel = UILabel()
        timeLabel.text = quake.time.formatted()
        timeLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [magnitudeLabel, placeLabel, timeLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            magnitudeLabel.widthAnchor.constraint(equalToConstant: 80),
            magnitudeLabel.heightAnchor.constraint(equalToConstant: 60),
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}

private extension UIFont {
    func bold() -> UIFont {
        UIFont(descriptor: fontDescriptor.withSymbolicTraits(.traitBold) ?? fontDescriptor, size: 0)
    }
}

/// Hosts `QuakeDetailViewController` in SwiftUI.
struct QuakeDetailView: UIViewControllerRepresentable {
    var quake: Quake

    func makeUIViewController(context: Context) -> QuakeDetailViewController {
        QuakeDetailViewController(quake: quake)
    }

    func updateUIViewController(_ uiViewController: QuakeDetailViewController, context: Context) {}
}
