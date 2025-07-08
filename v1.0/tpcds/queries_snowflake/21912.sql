
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_net_paid IS NOT NULL
),
MonthlySales AS (
    SELECT 
        d_year,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        ws_net_paid > 0
    GROUP BY 
        d_year
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ws.ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales)
),
NullCheckers AS (
    SELECT 
        COUNT(*) AS null_count,
        SUM(CASE WHEN ws_net_paid IS NULL THEN 1 ELSE 0 END) AS null_paid,
        SUM(CASE WHEN ws_net_paid IS NOT NULL THEN ws_net_paid ELSE 0 END) AS total_paid
    FROM 
        web_sales
)
SELECT 
    s.ws_item_sk,
    s.ws_order_number,
    s.rank,
    m.total_sales AS monthly_sales,
    m.order_count AS monthly_order_count,
    h.total_spent AS high_value_total,
    n.null_count,
    n.total_paid
FROM 
    RankedSales s
LEFT JOIN 
    MonthlySales m ON s.ws_item_sk = m.d_year
LEFT JOIN 
    HighValueCustomers h ON s.ws_order_number = h.c_customer_sk
CROSS JOIN 
    NullCheckers n
WHERE 
    s.rank = 1
    AND (m.total_sales IS NOT NULL OR h.total_spent IS NOT NULL)
ORDER BY 
    h.total_spent DESC, m.total_sales DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM web_sales) % 100;
