import { BadRequestException, Injectable } from "@nestjs/common";
import { getBattleWinner, stringToBytes } from "./battles.functions";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

@Injectable()
export class BattlesService {
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

  async getBattles() {
    const battles = await prisma.battles.findMany();
    return battles.map((battle) => ({
      ...battle,
      amountA: battle.amountA.toString(),
      amountB: battle.amountB.toString(),
      total: battle.total.toString(),
    }));
  }
}
