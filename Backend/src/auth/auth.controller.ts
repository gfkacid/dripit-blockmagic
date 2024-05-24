import { Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { LocalGuard } from './guards/local.guard';
import { JwtAuthGuard } from './guards/jwt.guard';
import { AuthService } from './auth.service';
import { authPaths } from './paths/auth.paths';
import { Request } from 'express';

@Controller(authPaths.main)
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post(authPaths.login)
  @UseGuards(LocalGuard)
  login(@Req() req: Request) {
    return req.user;
  }

  @Get(authPaths.status)
  @UseGuards(JwtAuthGuard)
  status(@Req() req: Request) {
    return req.user;
  }
}
