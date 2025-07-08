
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        (total_web_sales + total_catalog_sales + total_store_sales) AS grand_total,
        ROW_NUMBER() OVER (ORDER BY (total_web_sales + total_catalog_sales + total_store_sales) DESC) AS rank
    FROM CustomerSales c
),
SalesStats AS (
    SELECT
        wc.c_customer_sk,
        wc.c_first_name,
        wc.c_last_name,
        wc.grand_total,
        COUNT(DISTINCT CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_item_sk END) AS distinct_web_items,
        COUNT(DISTINCT CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_item_sk END) AS distinct_catalog_items,
        COUNT(DISTINCT CASE WHEN ss.ss_item_sk IS NOT NULL THEN ss.ss_item_sk END) AS distinct_store_items,
        (SELECT SUM(ws.ws_net_profit) FROM web_sales ws WHERE ws.ws_bill_customer_sk = wc.c_customer_sk) AS total_web_profit
    FROM TopCustomers wc
    LEFT JOIN web_sales ws ON wc.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON wc.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON wc.c_customer_sk = ss.ss_customer_sk
    GROUP BY wc.c_customer_sk, wc.c_first_name, wc.c_last_name, wc.grand_total
)
SELECT
    ss.c_first_name,
    ss.c_last_name,
    ss.grand_total,
    COALESCE(ss.distinct_web_items, 0) AS web_item_count,
    COALESCE(ss.distinct_catalog_items, 0) AS catalog_item_count,
    COALESCE(ss.distinct_store_items, 0) AS store_item_count,
    CASE 
        WHEN total_web_profit > 0.00 THEN 'Profitable'
        WHEN total_web_profit IS NULL THEN 'No Sales'
        ELSE 'Unprofitable' 
    END AS profitability_status
FROM SalesStats ss
WHERE ss.grand_total > (
    SELECT AVG(grand_total) FROM SalesStats
) 
OR ss.grand_total IS NULL
ORDER BY ss.grand_total DESC
LIMIT 10;
