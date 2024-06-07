import { Module } from "@nestjs/common";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";
import { BattlesController } from "./battles/battles.controller";
import { BattlesService } from "./battles/battles.service";
import { AuthModule } from "./auth/auth.module";
import { PositionsModule } from "./positions/positions.module";

@Module({
  imports: [AuthModule, PositionsModule],
  controllers: [AppController, BattlesController],
  providers: [AppService, BattlesService],
})
export class AppModule {}
