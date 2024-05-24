import { Injectable } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { User } from './types/User.type';

const prisma = new PrismaClient();

@Injectable()
export class AppService {
  async getUsers() {
    return await prisma.users.findMany();
  }

  async emailExist(email: string) {
    const results = await prisma.users.findMany({
      where: {
        email: email,
      },
    });
    return results.length > 0;
  }

  async createUser(data: User) {
    return await prisma.users.create({ data });
  }

  async validateUser(email: string, password: string) {
    const user = await prisma.users.findFirst({
      where: {
        email,
      },
    });

    if (!user) {
      return null;
    }

    const isPasswordValid = await bcrypt.compare(
      password,
      user.auth_identifier,
    );
    if (!isPasswordValid) {
      return null;
    }

    return user;
  }
}
