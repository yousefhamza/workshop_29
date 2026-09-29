/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sample login screen with email and password. There's no backend; it only validates input.
*/

import SwiftUI
import LuciqSDK

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var status: String?

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .luciq_privateView()
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .luciq_privateView()
                }

                Section {
                    Button("Log In", action: logIn)
                        .disabled(email.isEmpty || password.isEmpty)
                } footer: {
                    // Status echoes the email back, so keep it out of Luciq screenshots too.
                    if let status { Text(status).luciq_privateView() }
                }

                Section {
                    NavigationLink("Create an account") { SignupView() }
                }
            }
            .navigationTitle("Log In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func logIn() {
        guard email.isValidEmail else {
            status = "Enter a valid email address."
            return
        }
        status = "Logged in as \(email)."
    }
}

extension String {
    var isValidEmail: Bool {
        range(of: #"^[^@\s]+@[^@\s]+\.[^@\s]+$"#, options: .regularExpression) != nil
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
