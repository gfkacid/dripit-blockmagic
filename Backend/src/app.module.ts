import { Module } from "@nestjs/common";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";
import { SpotifyController } from "./spotify/spotify.controller";
import { SpotifyService } from "./spotify/spotify.service";
import { BattlesController } from "./battles/battles.controller";
import { BattlesService } from "./battles/battles.service";

@Module({
  imports: [],
  controllers: [AppController, BattlesController, SpotifyController],
  providers: [AppService, BattlesService, SpotifyService],
})
export class AppModule {}
