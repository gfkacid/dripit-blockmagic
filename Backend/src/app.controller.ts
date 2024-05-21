import { Controller, Get, Post, Body } from '@nestjs/common';
import { AppService } from './app.service';
import { userRoutes } from './routes/user.routes';
import { User } from './types/User.type';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get(userRoutes.getUsers)
  async getUsers() {
    return await this.appService.getUsers();
  }

  @Post(userRoutes.login)
  async login(@Body() body: { email: string; password: string }) {
    const user = await this.appService.validateUser(body.email, body.password);
    if (!user) {
      return { message: 'Invalid credentials' };
    }
    return user;
  }

  @Post(userRoutes.isEmailUsed)
  async isEmailUsed(@Body() data: { email: string }) {
    return await this.appService.emailExist(data.email);
  }

  @Post(userRoutes.createUser)
  async createUser(@Body() user: User) {
    const result = await this.appService.createUser(user);
    return result;
  }
}
