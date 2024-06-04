import { Module } from "@nestjs/common";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";
import { BattlesController } from "./battles/battles.controller";
import { BattlesService } from "./battles/battles.service";
import { AuthModule } from './auth/auth.module';

@Module({
  imports: [AuthModule],
  controllers: [AppController, BattlesController],
  providers: [AppService, BattlesService],
})
export class AppModule {}
