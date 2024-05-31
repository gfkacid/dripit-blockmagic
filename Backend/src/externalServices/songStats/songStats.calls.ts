import axios from "axios";
import { getSongStatsPayload } from "./sontStats.constants";
import { getSongStatsParams } from "./sontStats.types";

export const getSongStats = async (params: getSongStatsParams) => {
  try {
    const response = await axios(getSongStatsPayload(params));
    return response.data;
  } catch (error) {
    console.error("Error authorizing Spotify API", error);
    return null;
  }
};
