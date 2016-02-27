// Copyright (c) 2016 Giorgos Tsiapaliokas <giorgos.tsiapaliokas@mykolab.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit
import SnapKit

public class BannerView: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .ByWordWrapping
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .ByWordWrapping
        return label
    }()

    private var imageView: UIImageView?

    private let configuration: BannerViewConfiguration
    private weak var viewController: UIViewController!
    private var heightConstraint: Constraint?

    private var targetView: UIView {
        let targetView: UIView

        if configuration.position == .NavigationBar {
            targetView = self.viewController.view
        } else {
            targetView = UIApplication.sharedApplication()
                .windows[0]
        }

        return targetView
    }

    init(
        configuration: BannerViewConfiguration,
        viewController: UIViewController
    ) {
        self.configuration = configuration
        self.viewController = viewController
        super.init(frame: CGRectZero)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("Missing Implementation")
    }

    private func commonInit() {
        configureTitle()
        configureDescription()
        configureImage()
        setupConstraints()
    }

    private func configureTitle() {
        if let titleText = self.configuration.title {
            self.titleLabel.text = titleText
        }

        if let titleFont = self.configuration.titleFont {
            self.titleLabel.font = titleFont
        }

        if let titleColor = self.configuration.titleColor {
            self .titleLabel.textColor = titleColor
        }
    }

    private func configureDescription() {
        if let description = self.configuration.description {
            self.descriptionLabel.text = description
        }


        if let descriptionFont = self.configuration.descriptionFont {
            self.descriptionLabel.font = descriptionFont
        }

        if let descriptionColor = self.configuration.descriptionColor {
            self .descriptionLabel.textColor = descriptionColor
        }
    }

    private func configureImage() {
        if let image = self.configuration.image {
            let imageView = UIImageView(image: image)
            self.imageView = imageView

            if let imageColor = self.configuration.imageColor {
                self.imageView?.tintColor = imageColor
                self.imageView?.image = image
                    .imageWithRenderingMode(.AlwaysTemplate)
            } else {
                self.imageView = imageView
            }
        }
    }

    private func setupConstraints() {
        [
            self.titleLabel,
            self.descriptionLabel
        ].forEach() { addSubview($0) }

        if let imageView = self.imageView {
            addSubview(imageView)
            imageView.snp_makeConstraints() { make in
                make.centerY.equalTo(self)
                make.leading.equalTo(self).offset(10)
            }

            imageView.setContentHuggingPriority(1000, forAxis: .Horizontal)
        }

        self.titleLabel.snp_makeConstraints() { make in
            let offSet = self.configuration.position == .StatusBar ?
                UIApplication.sharedApplication().statusBarFrame.height
                : 0
            make.top.equalTo(self).offset(offSet)
        }

        self.descriptionLabel.snp_makeConstraints() { make in
            make.top.equalTo(self.titleLabel.snp_bottom).offset(10).priorityLow()
            make.bottom.equalTo(self).offset(-10)
        }

        [self.titleLabel, self.descriptionLabel].forEach() {
            $0.snp_makeConstraints() { make in
                make.trailing.equalTo(self).offset(-10)

                if let imageView = self.imageView {
                    make.leading.equalTo(imageView.snp_trailing).offset(10)
                } else {
                    make.leading.equalTo(self).offset(10)
                }
            }
        } // end forEach
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        guard let _ = self.superview else { return }

        self.translatesAutoresizingMaskIntoConstraints = false

        self.snp_makeConstraints() { make in
            make.leading.trailing.equalTo(self.targetView)
            if configuration.position == .NavigationBar {
                make.top.equalTo(self.viewController.snp_topLayoutGuideBottom)
                self.heightConstraint = make.bottom.equalTo(self.snp_top).constraint
            } else {
                self.heightConstraint = make.top.equalTo(self.targetView)
                    .offset(-self.targetView.frame.height / 2).constraint
            }

        }

        self.setContentCompressionResistancePriority(1000, forAxis: .Vertical)
    }

    public func show() {
        self.targetView.layoutIfNeeded()

        if self.configuration.position == .NavigationBar {
            self.heightConstraint?.deactivate()
        } else {
            self.heightConstraint?.updateOffset(0)
        }

        UIView.animateWithDuration(self.configuration.duration) {
            self.targetView.layoutIfNeeded()
        }
    }

    public func hide() {
        self.targetView.layoutIfNeeded()
        if self.configuration.position == .NavigationBar {
            self.heightConstraint?.activate()
        } else {
            self.heightConstraint?
                .updateOffset(-self.targetView.frame.height / 2)
        }

        UIView.animateWithDuration(self.configuration.duration,
        animations: {
            self.targetView.layoutIfNeeded()
        }) { _ in
            self.removeFromSuperview()
        }
    }
}