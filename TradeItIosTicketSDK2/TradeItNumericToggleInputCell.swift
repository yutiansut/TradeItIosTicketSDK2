import UIKit

class TradeItNumericToggleInputCell: UITableViewCell {
    @IBOutlet weak var textField: TradeItNumberField!
    @IBOutlet weak var quantityTypeToggle: UIButton!

    var onValueUpdated: ((_ newValue: NSDecimalNumber?) -> Void)?
    var onQuantityTypeToggled: ((_ newValue: String) -> Void)?

    override func awakeFromNib() {
        self.textField.padding = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        self.addDoneButtonToKeyboard()
    }

    func configure(
        initialValue: NSDecimalNumber?,
        placeholderText: String,
        isPrice: Bool = false,
        onValueUpdated: @escaping (_ newValue: NSDecimalNumber?) -> Void,
        onQuantityTypeToggled: @escaping (_ newValue: String) -> Void
    ) {
        self.onValueUpdated = onValueUpdated
        self.textField.placeholder = placeholderText
        self.textField.isPrice = isPrice

        if let initialValue = initialValue,
            initialValue != NSDecimalNumber.notANumber,
            initialValue.compare(NSDecimalNumber.zero) != ComparisonResult.orderedSame
        {
            self.textField.text = "\(initialValue)"
        } else {
            self.textField.text = ""
        }
    }

    func dismissKeyboard() {
        self.textField.resignFirstResponder()
    }

    // MARK: Private

    private func addDoneButtonToKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle = UIBarStyle.default

        let flexSpace = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace,
            target: nil,
            action: nil
        )

        let doneBarButtonItem: UIBarButtonItem  = UIBarButtonItem(
            title: "Done",
            style: UIBarButtonItemStyle.done,
            target: self,
            action: #selector(self.dismissKeyboard)
        )

        var barButtonItems = [UIBarButtonItem]()
        barButtonItems.append(flexSpace)
        barButtonItems.append(doneBarButtonItem)

        doneToolbar.items = barButtonItems
        doneToolbar.sizeToFit()

        self.textField.inputAccessoryView = doneToolbar
    }

    // MARK: IBActions

    @IBAction func textFieldDidChange(_ sender: TradeItNumberField) {
        let numericValue = NSDecimalNumber.init(string: sender.text)

        if numericValue == NSDecimalNumber.notANumber {
            self.onValueUpdated?(nil)
        } else {
            self.onValueUpdated?(numericValue)
        }
    }
}
