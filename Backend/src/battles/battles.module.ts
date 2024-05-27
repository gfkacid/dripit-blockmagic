import { Module } from '@nestjs/common';
import { BattlesController } from './battles.controller';
import { BattlesService } from './battles.service';

@Module({
  controllers: [BattlesController],
  providers: [BattlesService]
})
export class BattlesModule {}
