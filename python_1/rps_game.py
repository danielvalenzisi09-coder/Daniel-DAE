import random

# Function to display a welcome message
def display_welcome():
    """Display the welcome message for the game."""
    print("🎮 Welcome to Rock, Paper, Scissors!")
    print("Type 'rock', 'paper', or 'scissors' to play.")
    print("Type 'quit' to exit the game.\n")

# Function to get the computer's choice
def get_computer_choice(options_list):
    """Randomly choose rock, paper, or scissors for the computer."""
    return random.choice(options_list)

# Function to determine the winner
def determine_winner(player_choice, computer_choice):
    """Determine and return the winner of the round."""
    if player_choice == computer_choice:
        return "tie"
    elif (
        (player_choice == "rock" and computer_choice == "scissors") or
        (player_choice == "scissors" and computer_choice == "paper") or
        (player_choice == "paper" and computer_choice == "rock")
    ):
        return "player"
    else:
        return "computer"

# Function to play one round of the game
def play_round(options_list):
    """Play a single round of Rock, Paper, Scissors."""
    player_choice = input("Your choice: ").lower()
    
    if player_choice == "quit":
        return "quit", None

    if player_choice not in options_list:
        print("Invalid choice. Please try again.\n")
        return "invalid", None

    computer_choice = get_computer_choice(options_list)
    print(f"Computer chose: {computer_choice}")
    
    winner = determine_winner(player_choice, computer_choice)
    return winner, player_choice

# Main game loop
def play_game():
    """Main function to handle the game loop and scoring."""
    display_welcome()

    options = ["rock", "paper", "scissors"]  # List (sequence)
    player_score = 0  # Integer (data type 1)
    computer_score = 0
    rounds_played = 0

    while True:
        winner, choice = play_round(options)
        
        if winner == "quit":
            break
        elif winner == "invalid":
            continue
        elif winner == "tie":
            print("It's a tie!\n")
        elif winner == "player":
            print("You win this round!\n")
            player_score += 1
        elif winner == "computer":
            print("Computer wins this round!\n")
            computer_score += 1

        rounds_played += 1

    print("\n🎉 Game Over!")
    print(f"Rounds played: {rounds_played}")
    print(f"Your score: {player_score}")
    print(f"Computer score: {computer_score}")
    if player_score > computer_score:
        print("🏆 You win the game!")
    elif player_score < computer_score:
        print("💻 Computer wins the game!")
    else:
        print("🤝 It's a draw!")

# Start the game
play_game()
