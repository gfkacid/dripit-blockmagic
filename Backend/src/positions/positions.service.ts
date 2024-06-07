import { Injectable } from "@nestjs/common";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

@Injectable()
export class PositionsService {
  async getPositions(id: number) {
    const positions = id
      ? await prisma.positions.findMany({
          where: {
            user_id: id,
          },
        })
      : await prisma.positions.findMany();
    return positions.map((position) => ({
      ...position,
      amount: position.amount.toString(),
    }));
  }
}
