import { Controller, Post, Get, Body, Param } from '@nestjs/common';
import { SubscriptionService } from './subscription.service';
import { ActivateLicenseDto, GenerateLicenseDto } from './dto/activate-license.dto';

@Controller('subscription')
export class SubscriptionController {
  constructor(private readonly subscriptionService: SubscriptionService) {}

  @Post('activate')
  async activateLicense(@Body() dto: ActivateLicenseDto) {
    return this.subscriptionService.activateLicense(dto);
  }

  @Post('generate')
  async generateLicense(@Body() dto: GenerateLicenseDto) {
    return this.subscriptionService.generateLicense(dto);
  }

  @Get('status/:shopId')
  async getStatus(@Param('shopId') shopId: string) {
    return this.subscriptionService.getStatus(shopId);
  }
}
