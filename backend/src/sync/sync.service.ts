import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SyncPushDto } from './dto/sync.dto';

@Injectable()
export class SyncService {
  constructor(private readonly prisma: PrismaService) {}

  /// Push offline changes from POS to Cloud
  async push(dto: SyncPushDto) {
    if (!dto.shopId) {
      throw new BadRequestException('shopId is required for multi-tenant sync.');
    }

    // Ensure shop exists in cloud database
    await this.prisma.shop.upsert({
      where: { id: dto.shopId },
      update: {},
      create: {
        id: dto.shopId,
        name: 'My Store (Synced)',
        planTier: 'free',
        subscriptionStatus: 'active',
      },
    });

    const categories = dto.categories || [];
    const products = dto.products || [];
    const customers = dto.customers || [];
    const customerLedgers = dto.customerLedgers || [];
    const orders = dto.orders || [];
    const orderItems = dto.orderItems || [];

    // Execute upserts inside an ACID Prisma transaction
    await this.prisma.$transaction(async (tx) => {
      // 1. Categories
      for (const cat of categories) {
        await tx.category.upsert({
          where: { id: cat.id },
          update: {
            name: cat.name,
            colorCode: cat.colorCode,
            sortOrder: cat.sortOrder ?? 0,
            updatedAt: cat.updatedAt ? new Date(cat.updatedAt) : new Date(),
            deletedAt: cat.deletedAt ? new Date(cat.deletedAt) : null,
          },
          create: {
            id: cat.id,
            shopId: dto.shopId,
            name: cat.name,
            colorCode: cat.colorCode,
            sortOrder: cat.sortOrder ?? 0,
            createdAt: cat.createdAt ? new Date(cat.createdAt) : new Date(),
            updatedAt: cat.updatedAt ? new Date(cat.updatedAt) : new Date(),
            deletedAt: cat.deletedAt ? new Date(cat.deletedAt) : null,
          },
        });
      }

      // 2. Products
      for (const p of products) {
        await tx.product.upsert({
          where: { id: p.id },
          update: {
            name: p.name,
            categoryId: p.categoryId || null,
            barcode: p.barcode || null,
            costPrice: Number(p.costPrice) || 0.0,
            sellingPrice: Number(p.sellingPrice) || 0.0,
            stockQuantity: Number(p.stockQuantity) || 0,
            trackStock: Boolean(p.trackStock ?? true),
            imageUrl: p.imageUrl || null,
            isActive: Boolean(p.isActive ?? true),
            updatedAt: p.updatedAt ? new Date(p.updatedAt) : new Date(),
            deletedAt: p.deletedAt ? new Date(p.deletedAt) : null,
          },
          create: {
            id: p.id,
            shopId: dto.shopId,
            categoryId: p.categoryId || null,
            name: p.name,
            barcode: p.barcode || null,
            costPrice: Number(p.costPrice) || 0.0,
            sellingPrice: Number(p.sellingPrice) || 0.0,
            stockQuantity: Number(p.stockQuantity) || 0,
            trackStock: Boolean(p.trackStock ?? true),
            imageUrl: p.imageUrl || null,
            isActive: Boolean(p.isActive ?? true),
            createdAt: p.createdAt ? new Date(p.createdAt) : new Date(),
            updatedAt: p.updatedAt ? new Date(p.updatedAt) : new Date(),
            deletedAt: p.deletedAt ? new Date(p.deletedAt) : null,
          },
        });
      }

      // 3. Customers
      for (const c of customers) {
        await tx.customer.upsert({
          where: { id: c.id },
          update: {
            name: c.name,
            phone: c.phone || null,
            totalDebt: Number(c.totalDebt) || 0.0,
            updatedAt: c.updatedAt ? new Date(c.updatedAt) : new Date(),
            deletedAt: c.deletedAt ? new Date(c.deletedAt) : null,
          },
          create: {
            id: c.id,
            shopId: dto.shopId,
            name: c.name,
            phone: c.phone || null,
            totalDebt: Number(c.totalDebt) || 0.0,
            createdAt: c.createdAt ? new Date(c.createdAt) : new Date(),
            updatedAt: c.updatedAt ? new Date(c.updatedAt) : new Date(),
            deletedAt: c.deletedAt ? new Date(c.deletedAt) : null,
          },
        });
      }

      // 4. Customer Ledgers
      for (const l of customerLedgers) {
        await tx.customerLedger.upsert({
          where: { id: l.id },
          update: {
            amount: Number(l.amount) || 0.0,
            notes: l.notes || null,
            updatedAt: l.updatedAt ? new Date(l.updatedAt) : new Date(),
            deletedAt: l.deletedAt ? new Date(l.deletedAt) : null,
          },
          create: {
            id: l.id,
            shopId: dto.shopId,
            customerId: l.customerId,
            orderId: l.orderId || null,
            type: l.type,
            amount: Number(l.amount) || 0.0,
            notes: l.notes || null,
            createdAt: l.createdAt ? new Date(l.createdAt) : new Date(),
            updatedAt: l.updatedAt ? new Date(l.updatedAt) : new Date(),
            deletedAt: l.deletedAt ? new Date(l.deletedAt) : null,
          },
        });
      }

      // 5. Orders
      for (const o of orders) {
        await tx.order.upsert({
          where: { id: o.id },
          update: {
            orderNumber: o.orderNumber,
            subtotal: Number(o.subtotal) || 0.0,
            discountAmount: Number(o.discountAmount) || 0.0,
            taxAmount: Number(o.taxAmount) || 0.0,
            totalAmount: Number(o.totalAmount) || 0.0,
            paymentMethod: o.paymentMethod || 'CASH',
            status: o.status || 'COMPLETED',
            notes: o.notes || null,
            updatedAt: o.updatedAt ? new Date(o.updatedAt) : new Date(),
            deletedAt: o.deletedAt ? new Date(o.deletedAt) : null,
          },
          create: {
            id: o.id,
            shopId: dto.shopId,
            userId: o.userId || null,
            customerId: o.customerId || null,
            orderNumber: o.orderNumber,
            subtotal: Number(o.subtotal) || 0.0,
            discountAmount: Number(o.discountAmount) || 0.0,
            taxAmount: Number(o.taxAmount) || 0.0,
            totalAmount: Number(o.totalAmount) || 0.0,
            paymentMethod: o.paymentMethod || 'CASH',
            status: o.status || 'COMPLETED',
            notes: o.notes || null,
            createdAt: o.createdAt ? new Date(o.createdAt) : new Date(),
            updatedAt: o.updatedAt ? new Date(o.updatedAt) : new Date(),
            deletedAt: o.deletedAt ? new Date(o.deletedAt) : null,
          },
        });
      }

      // 6. Order Items
      for (const item of orderItems) {
        await tx.orderItem.upsert({
          where: { id: item.id },
          update: {
            productName: item.productName,
            quantity: Number(item.quantity) || 1,
            costPrice: Number(item.costPrice) || 0.0,
            unitPrice: Number(item.unitPrice) || 0.0,
            subtotal: Number(item.subtotal) || 0.0,
            updatedAt: item.updatedAt ? new Date(item.updatedAt) : new Date(),
            deletedAt: item.deletedAt ? new Date(item.deletedAt) : null,
          },
          create: {
            id: item.id,
            orderId: item.orderId,
            productId: item.productId,
            productName: item.productName,
            quantity: Number(item.quantity) || 1,
            costPrice: Number(item.costPrice) || 0.0,
            unitPrice: Number(item.unitPrice) || 0.0,
            subtotal: Number(item.subtotal) || 0.0,
            createdAt: item.createdAt ? new Date(item.createdAt) : new Date(),
            updatedAt: item.updatedAt ? new Date(item.updatedAt) : new Date(),
            deletedAt: item.deletedAt ? new Date(item.deletedAt) : null,
          },
        });
      }
    });

    return {
      success: true,
      serverTime: new Date().toISOString(),
      syncedCounts: {
        categories: categories.length,
        products: products.length,
        customers: customers.length,
        customerLedgers: customerLedgers.length,
        orders: orders.length,
        orderItems: orderItems.length,
      },
    };
  }

  /// Pull changes from Cloud to POS
  async pull(shopId: string, lastSyncedAt?: string) {
    if (!shopId) {
      throw new BadRequestException('shopId is required.');
    }

    const since = lastSyncedAt ? new Date(lastSyncedAt) : new Date(0);

    const [categories, products, customers, customerLedgers, orders] = await Promise.all([
      this.prisma.category.findMany({
        where: { shopId, updatedAt: { gt: since } },
      }),
      this.prisma.product.findMany({
        where: { shopId, updatedAt: { gt: since } },
      }),
      this.prisma.customer.findMany({
        where: { shopId, updatedAt: { gt: since } },
      }),
      this.prisma.customerLedger.findMany({
        where: { shopId, updatedAt: { gt: since } },
      }),
      this.prisma.order.findMany({
        where: { shopId, updatedAt: { gt: since } },
        include: { orderItems: true },
      }),
    ]);

    return {
      success: true,
      serverTime: new Date().toISOString(),
      changes: {
        categories,
        products,
        customers,
        customerLedgers,
        orders,
      },
    };
  }
}
