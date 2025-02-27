
WITH RECURSIVE SalesTrend AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
AvgCustomerProfile AS (
    SELECT 
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN CustomerPurchases cp ON cp.c_customer_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
TopItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_sales_price) > 1000
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    a.cd_gender,
    a.marital_status,
    a.avg_purchase_estimate,
    i.total_quantity_on_hand,
    t.total_sales,
    SUM(s.ws_quantity) AS total_quantity_sold,
    AVG(s.ws_net_profit) AS avg_net_profit
FROM AvgCustomerProfile a
LEFT JOIN InventoryStatus i ON i.inv_item_sk IN (SELECT DISTINCT si.ws_item_sk FROM web_sales si)
LEFT JOIN TopItems t ON t.ws_item_sk IN (SELECT DISTINCT st.ws_item_sk FROM store_sales st)
LEFT JOIN SalesTrend s ON s.ws_item_sk IN (SELECT DISTINCT si.ws_item_sk FROM web_sales si)
GROUP BY a.cd_gender, a.marital_status, a.avg_purchase_estimate, i.total_quantity_on_hand, t.total_sales
HAVING total_quantity_sold > 10
ORDER BY a.cd_gender, a.marital_status DESC;
