import { Controller, Get, Post, Body, Query, Req, Param } from "@nestjs/common";
import { BattlesService } from "./battles.service";
import { battlesRoutes } from "../routes/battles.routes";

@Controller(battlesRoutes.main)
export class BattlesController {
  constructor(private readonly battlesService: BattlesService) {}

  @Get()
  async getBattles(
    @Req() request: Request,
    @Query("artist") artist?: string,
    @Query("status") status?: string,
    @Query("created_by") createdBy?: string
  ) {
    const filters = { artist, status, createdBy };
    return await this.battlesService.getBattles(request, filters);
  }

  @Get(battlesRoutes.battleId)
  async get(@Param("id") id: number) {
    return await this.battlesService.getBattle(id);
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
