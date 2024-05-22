import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { SpotifyController } from './spotify/spotify.controller';
import { SpotifyService } from './spotify/spotify.service';

@Module({
  imports: [],
  controllers: [AppController, SpotifyController],
  providers: [AppService, SpotifyService],
})
export class AppModule {}
