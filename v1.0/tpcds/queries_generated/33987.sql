
WITH RECURSIVE CustomerTree AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ct.level + 1
    FROM customer c
    JOIN CustomerTree ct ON c.c_current_addr_sk = ct.c_current_addr_sk
    WHERE ct.level < 5
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerSales AS (
    SELECT 
        ct.c_customer_sk,
        ct.c_first_name || ' ' || ct.c_last_name AS full_name,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.order_count
    FROM CustomerTree ct
    LEFT JOIN SalesSummary ss ON ct.c_customer_sk = ss.ws_item_sk
),
IncomeDemo AS (
    SELECT 
        hd.hd_demo_sk, 
        CASE 
            WHEN ib.ib_lower_bound >= 0 AND ib.ib_upper_bound < 50000 THEN 'Low'
            WHEN ib.ib_lower_bound >= 50000 AND ib.ib_upper_bound < 100000 THEN 'Medium'
            ELSE 'High'
        END AS income_band
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cs.full_name,
    cs.total_quantity,
    cs.total_sales,
    id.income_band,
    CASE 
        WHEN cs.order_count > 0 THEN cs.total_sales / cs.order_count
        ELSE 0
    END AS avg_sales_per_order
FROM CustomerSales cs
JOIN IncomeDemo id ON cs.c_customer_sk = id.hd_demo_sk
WHERE cs.total_quantity > 0
ORDER BY cs.total_sales DESC
LIMIT 100
OFFSET 0;
