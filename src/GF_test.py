def gf128_mul(a, b, irreducible_poly):
    """
    Multiplies two numbers in GF(2^128) with a given irreducible polynomial.
    
    :param a: The first operand (128-bit integer).
    :param b: The second operand (128-bit integer).
    :param irreducible_poly: The irreducible polynomial for the field (128-bit integer).
    :return: The result of the multiplication modulo the irreducible polynomial.
    """
    result = 0
    for i in range(128):
        # If the least significant bit of b is 1, add a to the result
        if b & 1:
            result ^= a
        
        # Shift b to the right
        b >>= 1
        
        # Check if the most significant bit of a is 1
        carry = a & (1 << 127)
        
        # Shift a to the left
        a <<= 1
        
        # If there was a carry, reduce a modulo the irreducible polynomial
        if carry:
            a ^= irreducible_poly
    
    return result

# Example usage
b = 0x80000000000000000000000000000000  # Example 128-bit number
a = 0x80000000000000000000000000000000  # Example 128-bit number
irreducible_poly = 0x100000000000000000000000000000087  # AES irreducible polynomial for GF(2^128)

result = gf128_mul(a, b, irreducible_poly)
print(f"Multiplication result: {hex(result)}")
