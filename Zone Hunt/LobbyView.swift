//
//  LobbyView.swift
//  Zone Hunt
//
//  Created by Liam Colton on 9/11/24.
//

import SwiftUI
struct LobbyView: View {
    @State private var gameCode: String = ""
    @State private var isCreatingGame = false
    @State private var isJoiningGame = false
    let charLimit = 6
    var body: some View {
        NavigationView {
            ZStack{
                Image("BackgroundImage")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    Text("GeoTag Lobby")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .fontWeight(.heavy)
                        .padding(50)
                        .padding(.vertical)
                        .padding(.vertical)
                        .padding(.vertical)
                    Spacer()
                    Spacer()
                    // Create Game Button
                    NavigationLink(destination: CreateGameView())  {
                        Text("Create Game")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    
                    .padding(.horizontal)
                    TextField("Enter Game Code", text: $gameCode)
                        .keyboardType(.numberPad) // Ensures numeric keyboard on supported devices
                        .onChange(of: gameCode) {
                            if gameCode.count > charLimit {
                                    gameCode = String(gameCode.prefix(charLimit))
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal,17)
                        .padding(.vertical,5)
                        .cornerRadius(10)
                        
                    // Join Game Button
                    Button(action: {
                        self.isJoiningGame = true
                        print("Joining game with code: \(gameCode)")
                    }) {
                        Text("Join Game")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(gameCode.isEmpty ? Color.gray : Color.blue) // Gray if empty
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .disabled(gameCode.isEmpty) // Disable if no game code is entered
                    
                    Spacer()
                    
                    
                }
//                .navigationBarHidden(true)
            }
        }
    }
}
struct LobbyView_Previews: PreviewProvider {
    static var previews: some View {
        LobbyView()
    }
}


