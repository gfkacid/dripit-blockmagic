import { Controller, Get, Post, Body, Req } from "@nestjs/common";
import { BattlesService } from "./battles.service";
import { battlesRoutes } from "../routes/battles.routes";

@Controller(battlesRoutes.main)
export class BattlesController {
  constructor(private readonly battlesService: BattlesService) {}

  @Get()
  async getBattles(@Req() req: Request) {
    return await this.battlesService.getBattles(req);
  }

  @Post(battlesRoutes.resolveBattle)
  async resolveBattle(@Body() data: { id: number }) {
    return await this.battlesService.resolveBattle(data.id);
  }

  @Post(battlesRoutes.resolveBattles)
  async resolveBattles(@Body() data: { ids: number[] }) {
    return await this.battlesService.resolveBattlesBulk(data.ids);
  }
}
