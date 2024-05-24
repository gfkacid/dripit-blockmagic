import { spotifyRoutes } from '../externalRoutes/spotify.routes';

export const authOptions = {
  method: 'post',
  url: 'https://accounts.spotify.com/api/token',
  headers: {
    Authorization:
      'Basic ' +
      Buffer.from(
        process.env.SPOTIFY_CLIENT_ID + ':' + process.env.SPOTIFY_SECRET,
      ).toString('base64'),
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  data: new URLSearchParams({
    grant_type: 'client_credentials',
  }),
};
