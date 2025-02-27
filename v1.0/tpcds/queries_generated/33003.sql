
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk 
    WHERE c.c_customer_sk != ch.c_customer_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        ws.ws_sold_date_sk, 
        d.d_year, 
        d.d_month_seq, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_order_number) AS sales_rank
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
CustomerSales AS (
    SELECT 
        ch.c_customer_sk, 
        ch.c_first_name, 
        ch.c_last_name,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        COUNT(DISTINCT sd.ws_order_number) AS order_count,
        MAX(sd.ws_sales_price) AS max_sale
    FROM CustomerHierarchy ch
    JOIN SalesData sd ON ch.c_current_cdemo_sk = sd.ws_item_sk
    GROUP BY ch.c_customer_sk, ch.c_first_name, ch.c_last_name
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_sales,
    cs.order_count,
    CASE 
        WHEN cs.order_count > 0 THEN cs.total_sales / cs.order_count 
        ELSE 0 
    END AS avg_sales_per_order,
    CASE 
        WHEN cs.max_sale IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM CustomerSales cs
JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
WHERE cd.cd_marital_status = 'M' 
AND (cd.cd_dep_count > 2 OR cd.cd_credit_rating IS NULL)
ORDER BY cs.total_sales DESC
LIMIT 50;
