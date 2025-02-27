
WITH RECURSIVE income_summary AS (
    SELECT
        cb.hd_income_band_sk,
        COUNT(DISTINCT cb.hd_demo_sk) AS customer_count,
        SUM(cb.hd_buy_potential IS NULL) AS null_buy_potential_count,
        SUM(cb.hd_dep_count) AS total_dependent_count,
        SUM(cb.hd_vehicle_count) AS total_vehicle_count,
        CASE 
            WHEN AVG(cb.hd_buy_potential) IS NULL THEN 'UNKNOWN'
            WHEN AVG(cb.hd_buy_potential) < 0 THEN 'NEGATIVE'
            ELSE 'POSITIVE'
        END AS buy_potential_category
    FROM 
        household_demographics cb
    GROUP BY 
        cb.hd_income_band_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(CASE WHEN ws.ws_ext_discount_amt IS NULL THEN 0 ELSE ws.ws_ext_discount_amt END) AS total_discount,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 1 AND 1000 
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 0
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_customer_spending,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_order_value,
        SUM(ws.ws_ext_discount_amt) OVER (PARTITION BY c.c_customer_sk) AS total_discount_given
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        total_customer_spending > 100
)
SELECT
    cs.c_customer_sk,
    cs.total_customer_spending,
    cs.order_count,
    cs.avg_order_value,
    is.hd_income_band_sk,
    is.customer_count,
    is.null_buy_potential_count,
    is.total_dependent_count,
    CASE 
        WHEN cs.total_discount_given IS NULL THEN 0 
        ELSE cs.total_discount_given
    END AS effective_discount
FROM 
    customer_sales cs
LEFT JOIN 
    income_summary is ON cs.c_customer_sk = is.hd_income_band_sk 
WHERE 
    (cs.total_customer_spending - cs.total_discount_given) > 50
    AND cs.order_count > (
        SELECT 
            AVG(order_count)
        FROM 
            customer_sales
    )
ORDER BY 
    cs.total_customer_spending DESC
LIMIT 10
UNION ALL
SELECT 
    NULL, 
    NULL, 
    NULL, 
    NULL, 
    ib.ib_income_band_sk, 
    COUNT(*),
    SUM(CASE WHEN cb.hd_buy_potential IS NULL THEN 1 ELSE 0 END),
    SUM(cb.hd_dep_count),
    0 
FROM 
    income_band ib
LEFT JOIN 
    household_demographics cb ON ib.ib_income_band_sk = cb.hd_income_band_sk
GROUP BY 
    ib.ib_income_band_sk;
