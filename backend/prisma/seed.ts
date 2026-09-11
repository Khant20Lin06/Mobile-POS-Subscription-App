import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding initial demo licenses...');

  await prisma.license.upsert({
    where: { key: 'PRO-2026-DEMO-TEST' },
    update: {},
    create: {
      key: 'PRO-2026-DEMO-TEST',
      planTier: 'pro',
      durationDays: 365,
      isUsed: false,
    },
  });

  await prisma.license.upsert({
    where: { key: 'CUSTOM-2026-ENTERPRISE' },
    update: {},
    create: {
      key: 'CUSTOM-2026-ENTERPRISE',
      planTier: 'custom',
      durationDays: 730,
      isUsed: false,
    },
  });

  console.log('Demo licenses created:');
  console.log('1. PRO-2026-DEMO-TEST (Pro Plan - 1 Year)');
  console.log('2. CUSTOM-2026-ENTERPRISE (Custom/Enterprise Plan - 2 Years)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
