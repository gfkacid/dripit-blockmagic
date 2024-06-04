export class historyItem {
  date: string;
  popularity_current: number;
  followers_total: number;
  monthly_listeners_current: number;
  streams_current: number;
}

class platformStats {
  source: string;
  data: {
    history: historyItem[];
  };
}

export class songstatsApiResponse {
  result: string;
  message: string;
  stats: platformStats[];
}
