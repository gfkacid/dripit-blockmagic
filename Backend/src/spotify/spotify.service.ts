import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { authOptions } from './spotify.constants';
import axios from 'axios';

const prisma = new PrismaClient();

@Injectable()
export class SpotifyService {
  async authorize() {
    try {
      const response = await axios(authOptions);
      return response.data;
    } catch (error) {
      console.error('Error authorizing Spotify API', error);
      return null;
    }
  }
}
