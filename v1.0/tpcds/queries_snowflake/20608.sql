
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
AggregatedData AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
FilteredSales AS (
    SELECT ad.*,
           CASE 
               WHEN ad.total_orders = 0 THEN NULL 
               ELSE ad.total_sales / ad.total_orders 
           END AS avg_sales_per_order,
           CASE 
               WHEN ad.max_price IS NULL THEN 'No Sales'
               WHEN ad.max_price > 500 THEN 'High Roller'
               ELSE 'Regular'
           END AS customer_category
    FROM AggregatedData ad
    WHERE ad.total_quantity > 5
),
ComparativeResults AS (
    SELECT f.customer_category,
           AVG(f.avg_sales_per_order) AS average_per_category
    FROM FilteredSales f
    GROUP BY f.customer_category
)
SELECT 
    cr.customer_category,
    cr.average_per_category,
    COUNT(*) AS customer_count,
    LISTAGG(r.r_reason_desc, ', ') WITHIN GROUP (ORDER BY r.r_reason_desc) AS reasons
FROM ComparativeResults cr
LEFT JOIN store_returns sr ON sr.sr_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_customer_id IS NOT NULL)
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE cr.customer_category IS NOT NULL
GROUP BY cr.customer_category, cr.average_per_category
HAVING COUNT(*) > 1
ORDER BY cr.average_per_category DESC;
