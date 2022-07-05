module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    tsconfigRootDir: __dirname,
    project: [ './tsconfig.json' ]
  },
  plugins: [
    '@typescript-eslint'
  ],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:@typescript-eslint/recommended-requiring-type-checking'
  ],
  ignorePatterns: [
    'cdk.out',
    'dist',
    'node_modules',
    '.eslintrc.js'
  ],
  rules: {
    'array-bracket-spacing': [ 'error', 'always' ],
    'arrow-body-style': 'error',
    'arrow-parens': [ 'error', 'as-needed' ],
    'arrow-spacing': 'error',
    camelcase: [ 'error', { properties: 'never', ignoreDestructuring: false } ],
    'computed-property-spacing': 'error',
    'eqeqeq': 'error',
    'eol-last': [ 'error', 'always' ],
    indent: [ 'error', 2 ],
    'key-spacing': 'error',
    'linebreak-style': 'error',
    'new-parens': 'error',
    'no-new-object': 'error',
    'no-tabs': 'error',
    'no-trailing-spaces': 'error',
    'no-unneeded-ternary': 'error',
    'no-whitespace-before-property': 'error',
    'nonblock-statement-body-position': 'error',
    'object-curly-spacing': [ 'error', 'always' ],
    'quote-props': [ 'error', 'as-needed', { keywords: false, unnecessary: false } ],
    'rest-spread-spacing': 'error',
    'semi-spacing': 'error',
    'semi-style': 'error',
    'space-in-parens': 'error',

    '@typescript-eslint/comma-dangle': [ 'error', 'never' ],
    '@typescript-eslint/comma-spacing': 'error',
    '@typescript-eslint/func-call-spacing': 'error',
    '@typescript-eslint/keyword-spacing': [ 'error', { overrides: { return: { after: true }, throw: { after: true }, case: { after: true } } } ],
    '@typescript-eslint/no-array-constructor': 'error',
    '@typescript-eslint/no-explicit-any': [ 'error', { ignoreRestArgs: true } ],
    '@typescript-eslint/no-throw-literal': 'error',
    '@typescript-eslint/quotes': [ 'error', 'single', { allowTemplateLiterals: true } ],
    "@typescript-eslint/semi": 'error',
    '@typescript-eslint/unbound-method': 'off'
  }
};
