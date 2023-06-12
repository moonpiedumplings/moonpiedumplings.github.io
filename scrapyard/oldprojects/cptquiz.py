import os
import shelve


def clear():
    os.system('cls||clear')


class Quiz:
    def __init__(self, name):
        self.qs = {}
        counter = 1
        while(True):
            qname = input("Question "+str(counter)+" is? ")
            ansnum = int(input("How many answers in Question "+str(counter)+"? "))
            self.qs[qname] = []
            for i in range(ansnum):
                self.qs[qname].append(input("Answer "+str(i+1)+" is? "))
                if input("Is this answer correct? y / n ? ") == "y":
                    self.qs[qname][i] = self.qs[qname][i] +"asequenceofcharactersthatnoonewillaccidentallytype"  # Metadata, modifies correct answers.

            if input("Last question in the quiz? y or n ") == "y":
                break
            
            counter +=1
    def ask(self):
        answers = []
        correct = 0
        for i in self.qs:
            print(i)
            count = 0
            for z in self.qs[i]:
                if z[-50:] == "asequenceofcharactersthatnoonewillaccidentallytype":
                    print(str(count + 1)+". "+ z[:-50])
                    answers.append(z)
                else: 
                    print(str(count + 1)+". " + z)
                count =+ 1
            answer = int(input("Make your selection (pick a number): ")) - 1
            if self.qs[i][answer][-50:] == "asequenceofcharactersthatnoonewillaccidentallytype":
                correct += 1
        print("You got "+str(correct)+" questions correct, out of "+str(len(self.qs))+" questions")
        print("In percent format, that is "+str(100 * (correct / int(len(self.qs))))+"%")

store = shelve.open('store')

def quizzes(whattodo):
    print("Stored Quizzes:")
    quizarray = []
    for count, quiz in enumerate(store):
        print(str(count + 1)+". "+quiz)
        quizarray.append(quiz)
    if whattodo == "ask":
        selectquiz = int(input("Select a Quiz to do: ")) - 1
        store[quizarray[selectquiz]].ask()
    if whattodo == "recreate":
        selectquiz = int(input("Select a Quiz to recreate: ")) - 1
        store[quizarray[selectquiz]] = Quiz(quizarray[selectquiz])

        


clear()
while True:
    print("Welcome to the Quiz program")
    print("1. List Quizzes \n2. Create Quiz\n3. Do quiz \n4. Recreate Quiz from scratch\n5. Quit ")
    selection = input("Choose: ")
    if selection == "1":
        clear()
        quizzes("nothing")
    if selection == "2":
        clear()
        quizname = input("What would you like this quiz to be called? ")
        store[quizname] = Quiz(quizname)
    if selection == "3":
        clear()
        quizzes("ask")
    if selection == "4":
        clear()
        quizzes("recreate")
    if selection == "5":
        break

