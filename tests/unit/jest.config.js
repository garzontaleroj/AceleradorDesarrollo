module.exports = {
  testEnvironment: 'node',
  testMatch: ['**/*.test.js'],
  verbose: true,
  collectCoverageFrom: ['**/*.js', '!**/node_modules/**', '!jest.config.js'],
};
