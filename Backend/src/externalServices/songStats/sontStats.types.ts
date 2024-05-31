import { sourcesEnum } from "./sontStats.constants";

export class getSongStatsParams {
  start_date: string;
  end_date: string;
  source: typeof sourcesEnum;
  spotify_artist_id: string;
}
