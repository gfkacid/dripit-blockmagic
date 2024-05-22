import { Controller, Get, Post, Body } from '@nestjs/common';
import { SpotifyService } from './spotify.service';
import { spotifyRoutes } from '../routes/spotify.routes';

@Controller()
export class SpotifyController {
  constructor(private readonly SpotifyService: SpotifyService) {}

  @Get(spotifyRoutes.getToken)
  async getToken() {
    const result = await this.SpotifyService.authorize();
    return result;
  }
}
