import { BadRequestException, Injectable, Req } from "@nestjs/common";
import { getBattleWinner, stringToBytes } from "./battles.functions";
import { isRequestAuthorizedForUser } from "src/auth/auth.functions";
import { PositionsService } from "src/positions/positions.service";
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

  async getBattles(request: any) {
    const authorizedUser = await isRequestAuthorizedForUser(request);
    const battles = await prisma.battles.findMany();

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
