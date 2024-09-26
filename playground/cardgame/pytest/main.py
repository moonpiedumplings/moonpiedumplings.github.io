from node import *

newNode = hexnode()

newNode2 = hexnode()

newNode.connections["upright"] = newNode2

print(newNode.connections)