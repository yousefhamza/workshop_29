/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sample signup screen with email, password, password confirmation, and membership ID.
There's no backend; it only validates input.
*/

import SwiftUI

struct SignupView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var membershipID = ""
    @State private var status: String?

    private var isComplete: Bool {
        ![email, password, confirmPassword, membershipID].contains(where: \.isEmpty)
    }

    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                SecureField("Confirm password", text: $confirmPassword)
                    .textContentType(.newPassword)
            }

            Section("Membership") {
                TextField("Membership ID", text: $membershipID)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
            }

            Section {
                Button("Sign Up", action: signUp)
                    .disabled(!isComplete)
            } footer: {
                if let status { Text(status) }
            }
        }
        .navigationTitle("Sign Up")
    }

    private func signUp() {
        if !email.isValidEmail {
            status = "Enter a valid email address."
        } else if password.count < 8 {
            status = "Password must be at least 8 characters."
        } else if password != confirmPassword {
            status = "Passwords don't match."
        } else {
            status = "Account created for \(email) (membership \(membershipID))."
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { SignupView() }
    }
}
