import { sourcesEnum } from "./songStats.constants";

export class getSongStatsParams {
  start_date: string;
  end_date: string;
  source: string;
  spotify_artist_id: string;
}
