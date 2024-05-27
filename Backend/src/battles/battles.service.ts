import { BadRequestException, Injectable } from "@nestjs/common";
import { getWinningBattle } from "./battles.functions";
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

    return getWinningBattle(battleId, battleId);
  }
}
