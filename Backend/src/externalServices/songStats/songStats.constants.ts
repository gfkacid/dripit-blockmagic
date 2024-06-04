import { getSongStatsParams } from "./songStats.types";

export const sourcesEnum = {
  spotify: "spotify",
};

export const getSongStatsPayload = (params: getSongStatsParams) => {
  return {
    method: "get",
    url: "https://api.songstats.com/enterprise/v1/artists/historic_stats",
    headers: {
      apiKey: "ee22b0d9-4b51-496a-b57e-a37fd6c945e9",
    },
    params,
  };
};
