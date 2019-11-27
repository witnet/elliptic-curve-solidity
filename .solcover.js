module.exports = {
	norpc: false,
	testCommand: 'node --max-old-space-size=4096 ../node_modules/.bin/truffle test --network coverage --timeout 10000',
	compileCommand: 'node --max-old-space-size=4096 ../node_modules/.bin/truffle compile --network coverage'
}