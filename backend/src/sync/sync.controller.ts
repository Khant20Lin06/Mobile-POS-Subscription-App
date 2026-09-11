import { Controller, Post, Get, Body, Query } from '@nestjs/common';
import { SyncService } from './sync.service';
import { SyncPushDto } from './dto/sync.dto';

@Controller('sync')
export class SyncController {
  constructor(private readonly syncService: SyncService) {}

  @Post('push')
  async push(@Body() dto: SyncPushDto) {
    return this.syncService.push(dto);
  }

  @Get('pull')
  async pull(
    @Query('shopId') shopId: string,
    @Query('lastSyncedAt') lastSyncedAt?: string,
  ) {
    return this.syncService.pull(shopId, lastSyncedAt);
  }
}
