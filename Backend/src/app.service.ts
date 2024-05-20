import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import { User } from './types/User.type';

const prisma = new PrismaClient();

@Injectable()
export class AppService {
  async getUsers() {
    return await prisma.users.findMany();
  }

  async createUser(data: User) {
    return await prisma.users.create({ data });
  }
}
