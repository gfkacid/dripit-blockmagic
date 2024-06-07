import { BadRequestException, Injectable } from "@nestjs/common";
import { getBattleWinner, stringToBytes } from "./battles.functions";
import { isRequestAuthorizedForUser } from "src/auth/auth.functions";
import { PositionsService } from "src/positions/positions.service";
import { getBattlesParameters } from "src/types/Battles.types";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

@Injectable()
export class BattlesService {
  constructor(private positionsService: PositionsService) {}
  async resolveBattle(battleId: number) {
    const battle = await prisma.battles.findUnique({
      where: {
        id: battleId,
      },
    });

    if (!battle) {
      throw new BadRequestException(`Battle with ID ${battleId} not found`);
    }

    return getBattleWinner(battle);
  }

  async resolveBattlesBulk(battleIds: number[]) {
    const results = battleIds.map(async (battleId) => {
      const battle = await prisma.battles.findUnique({
        where: {
          id: battleId,
        },
      });
      return getBattleWinner(battle);
    });

    const resultsString = results.join("");
    return stringToBytes(resultsString);
  }

  async getBattles(request: Request, filters: getBattlesParameters) {
    const authorizedUser = await isRequestAuthorizedForUser(request);
    const { artist, status, createdBy } = filters;
    const where: any = {};

    if (artist) {
      where.OR = [
        { artists_battles_sideA_idToartists: { id: artist } },
        { artists_battles_sideB_idToartists: { id: artist } },
      ];
    }

    if (status) {
      where.status = parseInt(status, 10);
    }

    if (createdBy) {
      where.created_by = parseInt(createdBy, 10);
    }

    const battles = await prisma.battles.findMany({
      where,
      include: {
        artists_battles_sideA_idToartists: true,
        artists_battles_sideB_idToartists: true,
        users: true,
      },
    });

    if (authorizedUser) {
      const positions =
        await this.positionsService.getPositions(authorizedUser);
      return battles.map((battle) => {
        const userPosition = positions.find(
          (position) =>
            position.battle_id === battle.id &&
            position.user_id === authorizedUser
        );

        return {
          ...battle,
          amountA: battle.amountA.toString(),
          amountB: battle.amountB.toString(),
          total: battle.total.toString(),
          isBattleOwner: battle.created_by === authorizedUser,
          depositedAmount: userPosition?.amount ?? 0,
        };
      });
    }

    return battles.map((battle) => ({
      ...battle,
      amountA: battle.amountA.toString(),
      amountB: battle.amountB.toString(),
      total: battle.total.toString(),
    }));
  }
}
