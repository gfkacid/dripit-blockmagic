import { Module } from "@nestjs/common";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";
import { BattlesController } from "./battles/battles.controller";
import { BattlesService } from "./battles/battles.service";

@Module({
  imports: [],
  controllers: [AppController, BattlesController],
  providers: [AppService, BattlesService],
})
export class AppModule {}
