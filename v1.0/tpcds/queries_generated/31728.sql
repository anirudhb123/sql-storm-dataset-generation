
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, h.level + 1
    FROM customer c
    JOIN CustomerHierarchy h ON c.c_current_cdemo_sk = h.c_current_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        SUM(ws.ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.ws_item_sk
),
CustomerSales AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_revenue, 0) AS total_revenue
    FROM CustomerHierarchy ch
    LEFT JOIN SalesData sd ON ch.c_current_cdemo_sk = sd.ws_item_sk
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_quantity,
    cs.total_revenue,
    CASE 
        WHEN cs.total_revenue > 0 THEN cs.total_revenue / NULLIF(cs.total_quantity, 0)
        ELSE 0
    END AS avg_order_value,
    RANK() OVER (ORDER BY cs.total_revenue DESC) AS revenue_rank
FROM CustomerSales cs
WHERE cs.total_quantity > 10
UNION ALL
SELECT 
    NULL AS c_customer_sk, 
    'Total' AS c_first_name, 
    NULL AS c_last_name,
    SUM(total_quantity) AS total_quantity,
    SUM(total_revenue) AS total_revenue,
    CASE 
        WHEN SUM(total_revenue) > 0 THEN SUM(total_revenue) / NULLIF(SUM(total_quantity), 0)
        ELSE 0
    END AS avg_order_value,
    NULL AS revenue_rank
FROM CustomerSales
HAVING SUM(total_revenue) > 1000
ORDER BY 6 DESC
LIMIT 10;
