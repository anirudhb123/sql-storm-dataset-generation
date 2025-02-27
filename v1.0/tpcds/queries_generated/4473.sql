
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_paid DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND ws.ws_sold_date_sk IN (
            SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq = 3
        )
),

AggregatedSales AS (
    SELECT
        web_site_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue
    FROM 
        RankedSales
    GROUP BY 
        web_site_id
)

SELECT 
    s.warehouse_id,
    COALESCE(a.total_quantity, 0) AS total_quantity,
    COALESCE(a.total_revenue, 0.00) AS total_revenue,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)) AS total_store_sales
FROM 
    warehouse s
LEFT JOIN 
    AggregatedSales a ON s.warehouse_sk = (
        SELECT ws.ws_warehouse_sk 
        FROM web_sales ws 
        WHERE ws.ws_order_number IN (SELECT ws_order_number FROM RankedSales)
        LIMIT 1
    )
ORDER BY 
    total_revenue DESC
LIMIT 10
UNION ALL
SELECT 
    'Total' AS warehouse_id,
    SUM(total_quantity),
    SUM(total_revenue)
FROM 
    AggregatedSales
ORDER BY 
    total_revenue DESC;
