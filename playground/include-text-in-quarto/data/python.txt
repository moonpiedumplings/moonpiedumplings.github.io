# A function to check if a number is prime
def is_prime(n):
  # If n is less than 2, it is not prime
  if n < 2:
    return False
  # Loop from 2 to the square root of n
  for i in range(2, int(n**0.5) + 1):
    # If n is divisible by i, it is not prime
    if n % i == 0:
      return False
  # If no divisor is found, it is prime
  return True

# Test the function with some numbers
print(is_prime(2)) # True
print(is_prime(3)) # True
print(is_prime(4)) # False
print(is_prime(5)) # True
print(is_prime(6)) # False
