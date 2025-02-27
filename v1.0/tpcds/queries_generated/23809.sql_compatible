
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_net_paid,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_net_paid IS NOT NULL
    AND ws.ws_net_paid > (
        SELECT AVG(ws_1.ws_net_paid)
        FROM web_sales ws_1
        WHERE ws_1.ws_item_sk = ws.ws_item_sk
    )
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_net_paid IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING SUM(ws.ws_net_paid) > 1000
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE(SUM(ss.ss_sales_price), 0) AS total_sales_price,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_quantity_sold
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY i.i_item_sk, i.i_product_name
    HAVING SUM(ss.ss_sales_price) IS NOT NULL
),
SalesSummary AS (
    SELECT 
        rv.ws_item_sk,
        SUM(rv.ws_net_paid) AS total_net_paid,
        AVG(rv.ws_sales_price) AS avg_sales_price
    FROM RankedSales rv
    GROUP BY rv.ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    hv.total_spent AS customer_total_spent,
    ti.total_sales_price,
    ti.total_quantity_sold,
    CASE 
        WHEN hv.order_count IS NULL THEN 'No Orders'
        ELSE CAST(hv.order_count AS VARCHAR) || ' Orders'
    END AS order_status,
    COALESCE(ss.total_net_paid, 0) AS total_net_paid_for_high_value_items
FROM HighValueCustomers hv
JOIN TopItems ti ON hv.order_count > 5 
LEFT JOIN SalesSummary ss ON ti.i_item_sk = ss.ws_item_sk
WHERE hv.total_spent > (SELECT MAX(total_spent) FROM HighValueCustomers) / 2
ORDER BY ti.total_sales_price DESC, customer_total_spent ASC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
