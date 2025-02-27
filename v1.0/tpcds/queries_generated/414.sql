
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0)) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
income_distribution AS (
    SELECT
        hd.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cs.total_net_paid) AS avg_spent
    FROM 
        household_demographics hd
    JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        customer_sales cs ON c.c_customer_id = cs.c_customer_id
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(id.customer_count, 0) AS customer_count,
    COALESCE(id.avg_spent, 0.00) AS avg_spent
FROM 
    income_band ib
LEFT JOIN 
    income_distribution id ON ib.ib_income_band_sk = id.hd_income_band_sk
ORDER BY 
    ib.ib_income_band_sk
UNION ALL
SELECT 
    NULL AS ib_income_band_sk,
    NULL AS ib_lower_bound,
    NULL AS ib_upper_bound,
    COUNT(c.c_customer_sk) AS customer_count,
    AVG(cs.total_net_paid) AS avg_spent
FROM 
    customer c
JOIN 
    customer_sales cs ON c.c_customer_id = cs.c_customer_id
WHERE 
    cs.total_net_paid IS NOT NULL;
