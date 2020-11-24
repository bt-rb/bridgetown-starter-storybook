const port = process.env.SERVER_PORT || 4000;

export const parameters = {
  server: {
    url: `http://localhost:${port}/components`,
  }
};
