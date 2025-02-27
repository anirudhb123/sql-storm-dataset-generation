
WITH RECURSIVE SalesTrend AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_sold_time_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(ws_sold_date_sk) FROM web_sales)
    GROUP BY ws_sold_date_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        rn + 1
    FROM web_sales
    JOIN SalesTrend ON ws_sold_date_sk = SalesTrend.ws_sold_date_sk + INTERVAL '1 day'
    GROUP BY ws_sold_date_sk
    HAVING rn < 30
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN c.c_customer_sk END) AS male_customers,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN c.c_customer_sk END) AS female_customers
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    s.ws_sold_date_sk,
    s.total_sales,
    cs.total_orders,
    cs.total_spent,
    COALESCE(cs.male_customers, 0) AS male_customers,
    COALESCE(cs.female_customers, 0) AS female_customers,
    CASE 
        WHEN s.total_sales > 1000 THEN 'High'
        WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM SalesTrend s
LEFT JOIN CustomerStats cs ON cs.c_customer_sk = 
    (SELECT c.c_customer_sk FROM customer c ORDER BY random() LIMIT 1)
ORDER BY s.ws_sold_date_sk DESC, s.total_sales DESC;
