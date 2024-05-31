import { Battle } from "../types/Battles.types";
import { getSongStats } from "../externalServices/songStats/songStats.calls";
import { getSongStatsParams } from "src/externalServices/songStats/songStats.types";
import { sourcesEnum } from "src/externalServices/songStats/songStats.constants";
import { songstatsApiResponse } from "src/types/Sontstats.types";
import { formatDateToYMD } from "src/helpers/date.helpers";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const getArtistPlaycount = async (params: getSongStatsParams) => {
  const songStats: songstatsApiResponse = await getSongStats(params);
  const initialStats = songStats.stats[0].data.history.at(0);
  const finalStats = songStats.stats[0].data.history.at(-1);
  return finalStats.streams_current - initialStats.streams_current;
};

export const getBattleWinner = async (battle: Battle) => {
  const artistA = await prisma.artists.findUnique({
    where: {
      id: battle.sideA_id,
    },
  });
  const artistB = await prisma.artists.findUnique({
    where: {
      id: battle.sideB_id,
    },
  });

  const makeParams = (spotify_artist_id: string) => {
    return {
      start_date: formatDateToYMD(battle.start_date),
      end_date: formatDateToYMD(battle.end_date),
      source: sourcesEnum.spotify,
      spotify_artist_id,
    };
  };

  const sideA_playcount = await getArtistPlaycount(
    makeParams(artistA.spotify_id)
  );

  const sideB_playcount = await getArtistPlaycount(
    makeParams(artistB.spotify_id)
  );

  return sideA_playcount > sideB_playcount ? 0 : 1;
};
