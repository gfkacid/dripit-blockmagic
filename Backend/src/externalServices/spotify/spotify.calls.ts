import axios from "axios";
import { getSpotifyTokenPayload } from "./spotify.constants";

export const getSpotifyToken = async () => {
  try {
    const response = await axios(getSpotifyTokenPayload);
    return response.data;
  } catch (error) {
    console.error("Error authorizing Spotify API", error);
    return null;
  }
};
