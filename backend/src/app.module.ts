import { Module } from '@nestjs/common';
import { PrismaModule } from './prisma/prisma.module';
import { SubscriptionModule } from './subscription/subscription.module';
import { SyncModule } from './sync/sync.module';

@Module({
  imports: [
    PrismaModule,
    SubscriptionModule,
    SyncModule,
  ],
})
export class AppModule {}
