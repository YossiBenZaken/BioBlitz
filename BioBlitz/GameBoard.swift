//
//  GameBoard.swift
//  BioBlitz
//
//  Created by Yosef Ben Zaken on 27/03/2023.
//

import SwiftUI

class GameBoard: ObservableObject {
    let rowCount = 11
    let columnCount = 22
    
    @Published var grid = [[Bacteria]]()
    
    @Published var currentPlayer = Color.green
    @Published var greenScore = 1
    @Published var redScore = 1
    
    @Published var winner: String? = nil
    
    private var bacteriaBeingInfected = 0
    
    init() {
        reset()
    }
    
    func reset() {
        winner = nil
        currentPlayer = .green
        redScore = 1
        greenScore = 1
        
        grid.removeAll()
        
        for row in 0..<rowCount {
            var newRow = [Bacteria]()
            
            for col in 0..<columnCount {
                let bacteria = Bacteria(row: row, col: col)
                
                if row <= rowCount / 2 {
                    if row == 0 && col == 0 {
                        // make sure the player starts pointing away from anything
                        bacteria.direction = .north
                    } else if row == 0 && col == 1 {
                        // make sure nothing points to the player
                        bacteria.direction = .east
                    } else if row == 1 && col == 0{
                        // make sure nothing points to the player
                        bacteria.direction = .south
                    } else {
                        // all other pieces are random
                        bacteria.direction = Bacteria.Direction.allCases.randomElement()!
                    }
                } else {
                    // mirror the counterpart
                    if let counterpart = getBacteria(atRow: rowCount - 1 - row, col: columnCount - 1 - col){
                        bacteria.direction = counterpart.direction.opposite
                    }
                }
                
                newRow.append(bacteria)
            }
            grid.append(newRow)
        }
        
        grid[0][0].color = .green
        grid[rowCount - 1][columnCount - 1].color = .red
    }
    
    func getBacteria(atRow row: Int, col: Int) -> Bacteria? {
        guard row >= 0 else {return nil}
        guard row < grid.count else {return nil}
        guard col >= 0 else {return nil}
        guard col < grid[0].count else {return nil}
        return grid[row][col]
    }
    
    func infect(from: Bacteria) {
        objectWillChange.send()
        
        var bacteriaToInject = [Bacteria?]()
        
        switch from.direction {
        case .north:
            bacteriaToInject.append(getBacteria(atRow: from.row - 1, col: from.col))
        case .south:
            bacteriaToInject.append(getBacteria(atRow: from.row + 1, col: from.col))
        case .east:
            bacteriaToInject.append(getBacteria(atRow: from.row, col: from.col + 1))
        case .west:
            bacteriaToInject.append(getBacteria(atRow: from.row, col: from.col - 1))
        }
        
        // indirect infection from above
        if let indirect = getBacteria(atRow: from.row - 1, col: from.col) {
            if indirect.direction == .south {
                bacteriaToInject.append(indirect)
            }
        }
        // indirect infection from below
        if let indirect = getBacteria(atRow: from.row + 1, col: from.col) {
            if indirect.direction == .north {
                bacteriaToInject.append(indirect)
            }
        }
        // indirect infection from left
        if let indirect = getBacteria(atRow: from.row, col: from.col - 1) {
            if indirect.direction == .east {
                bacteriaToInject.append(indirect)
            }
        }
        // indirect infection from right
        if let indirect = getBacteria(atRow: from.row, col: from.col + 1) {
            if indirect.direction == .west {
                bacteriaToInject.append(indirect)
            }
        }

        
        for case let bacteria? in bacteriaToInject {
            if bacteria.color != from.color {
                bacteria.color = from.color
                
                bacteriaBeingInfected += 1
                
                Task { @MainActor in
                    try await Task.sleep(for: .milliseconds(50))
                    bacteriaBeingInfected -= 1
                    infect(from: bacteria)
                }
                
            }
        }
        
        updateScores()
    }
    
    func rotate(bacteria: Bacteria) {
        guard bacteria.color == currentPlayer else {return}
        guard bacteriaBeingInfected == 0 else {return}
        guard winner == nil else {return}
        objectWillChange.send()
        
        bacteria.direction = bacteria.direction.next
        
        infect(from: bacteria)
    }
    
    func changePlayer() {
        if currentPlayer == .green {
            currentPlayer = .red
        } else {
            currentPlayer = .green
        }
    }
    
    func updateScores() {
        var newRedScore = 0
        var newGreenScore = 0
        
        for row in grid {
            for bacteria in row {
                if bacteria.color == .red {
                    newRedScore += 1
                }
                else if bacteria.color == .green {
                    newGreenScore += 1
                }
            }
        }
        redScore = newRedScore
        greenScore = newGreenScore
        
        if bacteriaBeingInfected == 0 {
            withAnimation(.spring()) {
                if redScore == 0 {
                    winner = "Green"
                } else if greenScore == 0 {
                    winner = "Red"
                } else {
                    changePlayer()
                }
            }
        }
    }
}
