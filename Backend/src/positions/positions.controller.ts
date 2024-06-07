import { Controller, Get, Post, Body, Req } from "@nestjs/common";
import { PositionsService } from "./positions.service";
import { positionsRoutes } from "../routes/positions.routes";

@Controller(positionsRoutes.main)
export class PositionsController {
  constructor(private readonly positionsService: PositionsService) {}

  @Get()
  async getPositions(@Req() req: any) {
    const id: number = Number(req.query.id);
    return await this.positionsService.getPositions(id);
  }
}
