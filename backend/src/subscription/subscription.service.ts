import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ActivateLicenseDto, GenerateLicenseDto } from './dto/activate-license.dto';
import * as crypto from 'crypto';

@Injectable()
export class SubscriptionService {
  constructor(private readonly prisma: PrismaService) {}

  /// Activate subscription license key issued via Telegram
  async activateLicense(dto: ActivateLicenseDto) {
    const cleanKey = dto.licenseKey.trim().toUpperCase();

    // Find license key
    const license = await this.prisma.license.findUnique({
      where: { key: cleanKey },
    });

    if (!license) {
      throw new BadRequestException('License key does not exist. Please contact Telegram @YourPOS_Admin.');
    }

    if (license.isUsed && license.usedByShopId !== dto.shopId) {
      throw new BadRequestException('This license key has already been activated by another shop.');
    }

    const now = new Date();
    const expiresAt = new Date(now.getTime() + license.durationDays * 24 * 60 * 60 * 1000);

    const shopName = dto.shopName || `Shop ${dto.shopId}`;

    // Update Shop and Mark License as used inside a transaction
    const [shop] = await this.prisma.$transaction([
      this.prisma.shop.upsert({
        where: { id: dto.shopId },
        update: {
          name: shopName,
          planTier: license.planTier,
          subscriptionStatus: 'active',
          subscriptionExpiresAt: expiresAt,
          licenseKey: license.key,
        },
        create: {
          id: dto.shopId,
          name: shopName,
          planTier: license.planTier,
          subscriptionStatus: 'active',
          subscriptionExpiresAt: expiresAt,
          licenseKey: license.key,
        },
      }),
      this.prisma.license.update({
        where: { key: cleanKey },
        data: {
          isUsed: true,
          usedByShopId: dto.shopId,
        },
      }),
    ]);

    return {
      success: true,
      shopId: shop.id,
      shopName: shop.name,
      planTier: shop.planTier,
      subscriptionStatus: shop.subscriptionStatus,
      expiresAt: shop.subscriptionExpiresAt,
      message: `Congratulations! ${shop.planTier.toUpperCase()} Plan is activated until ${expiresAt.toLocaleDateString()}.`,
    };
  }

  /// Admin endpoint to generate license key for customers paying via Telegram
  async generateLicense(dto: GenerateLicenseDto) {
    const tier = (dto.planTier || 'pro').toLowerCase();
    const days = dto.durationDays || 365;
    const year = new Date().getFullYear();
    const randomHex1 = crypto.randomBytes(2).toString('hex').toUpperCase();
    const randomHex2 = crypto.randomBytes(2).toString('hex').toUpperCase();
    const key = `${tier.toUpperCase()}-${year}-${randomHex1}-${randomHex2}`;

    const license = await this.prisma.license.create({
      data: {
        key,
        planTier: tier,
        durationDays: days,
      },
    });

    return {
      success: true,
      licenseKey: license.key,
      planTier: license.planTier,
      durationDays: license.durationDays,
      instructions: `Give this key to customer on Telegram. They can enter it in the POS app to activate.`,
    };
  }

  /// Get status of a shop subscription
  async getStatus(shopId: string) {
    const shop = await this.prisma.shop.findUnique({
      where: { id: shopId },
    });

    if (!shop) {
      return {
        shopId,
        planTier: 'free',
        subscriptionStatus: 'active',
        isExpired: false,
      };
    }

    const isExpired = shop.subscriptionExpiresAt ? new Date() > shop.subscriptionExpiresAt : false;

    return {
      shopId: shop.id,
      shopName: shop.name,
      planTier: isExpired ? 'free' : shop.planTier,
      subscriptionStatus: isExpired ? 'expired' : shop.subscriptionStatus,
      expiresAt: shop.subscriptionExpiresAt,
      isExpired,
    };
  }
}
