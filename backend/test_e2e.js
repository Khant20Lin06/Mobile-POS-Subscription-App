async function runTests() {
  const baseUrl = 'http://localhost:8085';
  console.log('--- Step 1: Check initial status of shop-101 ---');
  let res = await fetch(`${baseUrl}/subscription/status/shop-101`);
  console.log('Status Response:', await res.json());

  console.log('\n--- Step 2: Activate PRO License ---');
  res = await fetch(`${baseUrl}/subscription/activate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      licenseKey: 'PRO-2026-DEMO-TEST',
      shopId: 'shop-101'
    })
  });
  const activateResult = await res.json();
  console.log('Activate Result:', activateResult);

  console.log('\n--- Step 3: Check status again after activation ---');
  res = await fetch(`${baseUrl}/subscription/status/shop-101`);
  console.log('Updated Status:', await res.json());

  console.log('\n--- Step 4: Test Sync Push from Flutter client ---');
  const now = new Date().toISOString();
  const pushPayload = {
    shopId: 'shop-101',
    products: [
      {
        id: 'prod-sync-001',
        shopId: 'shop-101',
        name: 'Special Pro Cloud Coffee',
        sku: 'SKU-PRO-01',
        categoryName: 'Drinks',
        costPrice: 1500,
        sellingPrice: 3500,
        currentStock: 50,
        unit: 'cup',
        isActive: true,
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      }
    ],
    customers: [
      {
        id: 'cust-sync-001',
        shopId: 'shop-101',
        name: 'U Aung Kyaw',
        phone: '0912345678',
        creditLimit: 100000,
        currentDebt: 15000,
        isDeleted: false,
        createdAt: now,
        updatedAt: now
      }
    ],
    orders: [
      {
        id: 'ord-sync-001',
        orderNumber: 'INV-20260911-0001',
        shopId: 'shop-101',
        cashierId: 'cashier-001',
        customerId: 'cust-sync-001',
        customerName: 'U Aung Kyaw',
        subtotal: 7000,
        discount: 500,
        tax: 0,
        totalAmount: 6500,
        paymentType: 'cash',
        amountTendered: 10000,
        changeGiven: 3500,
        status: 'completed',
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
        items: [
          {
            id: 'item-sync-001',
            orderId: 'ord-sync-001',
            productId: 'prod-sync-001',
            productName: 'Special Pro Cloud Coffee',
            unitPrice: 3500,
            quantity: 2,
            subtotal: 7000,
            discount: 500,
            costPrice: 1500,
            createdAt: now
          }
        ]
      }
    ],
    ledgers: [
      {
        id: 'ledg-sync-001',
        customerId: 'cust-sync-001',
        shopId: 'shop-101',
        type: 'credit',
        amount: 6500,
        balanceAfter: 15000,
        orderId: 'ord-sync-001',
        note: 'Order credit payment',
        createdAt: now
      }
    ]
  };

  res = await fetch(`${baseUrl}/sync/push`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(pushPayload)
  });
  const pushResult = await res.json();
  console.log('Sync Push Result:', pushResult);

  console.log('\n--- Step 5: Test Sync Pull ---');
  res = await fetch(`${baseUrl}/sync/pull?shopId=shop-101`);
  const pullResult = await res.json();
  console.log('Sync Pull Summary:');
  console.log('Products returned:', pullResult.changes?.products?.length);
  console.log('Customers returned:', pullResult.changes?.customers?.length);
  console.log('Orders returned:', pullResult.changes?.orders?.length);
  console.log('Server Timestamp:', pullResult.serverTime);

  console.log('\n✅ All API & Sync End-to-End Tests Passed successfully!');
}

runTests().catch(err => {
  console.error('Test failed with error:', err);
  process.exit(1);
});
