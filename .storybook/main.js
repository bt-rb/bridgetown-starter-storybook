module.exports = {
  stories: ['../stories/**/*.stories.json'],
  logLevel: 'debug',
  addons: [{
    name: '@storybook/addon-essentials',
    options: {
      controls: false,
      actions: false,
      docs: false
    }
  }]
};
