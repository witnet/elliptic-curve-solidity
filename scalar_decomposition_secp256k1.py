import sys

minusLambda = 0xAC9C52B33FA3CF1F5AD9E3FD77ED9BA4A880B9FC8EC739C2E0CFC810B51283CF
minusB1 = 0x00000000000000000000000000000000E4437ED6010E88286F547FA90ABFE4C3
minusB2 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE8A280AC50774346DD765CDA83DB1562C
g1 = 0x00000000000000000000000000003086D221A7D46BCDE86C90E49284EB153DAB
g2 = 0x0000000000000000000000000000E4437ED6010E88286F547FA90ABFE4C42212
group = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

def roundedDiv(a, dividend):
  return int(round(a/pow(2, dividend)))

def split(num):

  c1 = roundedDiv(num*g1, 272)
  c2 = roundedDiv(num*g2, 272)
  c1 = (c1*minusB1) % group
  c2 = (c2*minusB2) % group
  r2 = (c1+c2) % group
  r1 = (r2*minusLambda) % group
  r1 = (r1+num) % group
  return(r1, r2)


if len(sys.argv) < 2:
  print("Please input an scalar in decimal form")

elif len(sys.argv) > 2:
  print("Wrong number of arguments")

else:
  print("The decomposition is:")
  print(split(int(sys.argv[1])))
