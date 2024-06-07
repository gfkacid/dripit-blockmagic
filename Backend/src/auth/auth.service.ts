import { Injectable } from "@nestjs/common";
import { AuthPayloadDto, SignMessageContent } from "./dto/auth.dto";
import { PrismaClient } from "@prisma/client";
import { JwtService } from "@nestjs/jwt";
import * as bcrypt from "bcryptjs";

const prisma = new PrismaClient();

@Injectable()
export class AuthService {
  constructor(private jwtService: JwtService) {}

  async validateUser(payload: AuthPayloadDto) {
    const { email, password } = payload;
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
      user.auth_identifier
    );
    if (!isPasswordValid) {
      return null;
    }

    const { id } = user;
    const signMessage: SignMessageContent = { id, email };
    return this.jwtService.sign(signMessage);
  }
}
