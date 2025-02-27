
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cs.total_sales,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_sales DESC) as sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
)
SELECT 
    tc.first_name || ' ' || tc.last_name AS full_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.order_count, 0) AS order_count,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales >= 1000 THEN 'High Roller'
        ELSE 'Occasional Buyer'
    END AS customer_category
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;

SELECT 
    w.w_warehouse_name,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_net_paid) AS avg_net_paid
FROM 
    web_sales ws
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
GROUP BY 
    w.w_warehouse_name
HAVING 
    total_profit > 5000
ORDER BY 
    avg_net_paid ASC;

SELECT 
    DISTINCT r.r_reason_desc,
    COUNT(cr.returning_customer_sk) AS return_count
FROM 
    catalog_returns cr
JOIN 
    reason r ON cr.cr_reason_sk = r.r_reason_sk
WHERE 
    cr.cr_return_quantity > 1
GROUP BY 
    r.r_reason_desc
ORDER BY 
    return_count DESC;

SELECT 
    ib.ib_income_band_sk AS income_band,
    COUNT(DISTINCT c.c_customer_id) AS customer_count
FROM  
    household_demographics hd
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN 
    customer c ON hd.hd_demo_sk = c.c_current_cdemo_sk
WHERE 
    hd.hd_buy_potential = 'High'
GROUP BY 
    ib.ib_income_band_sk
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY 
    income_band;

SELECT 
    s.s_store_name,
    SUM(ss.ss_net_profit) AS total_profit,
    AVG(ss.ss_sales_price) AS avg_sales_price
FROM 
    store_sales ss
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
WHERE 
    ss.ss_sold_date_sk IN (SELECT d.d_date_sk 
                            FROM date_dim d 
                            WHERE d.d_year = 2023)
GROUP BY 
    s.s_store_name
HAVING 
    total_profit >= 10000
ORDER BY 
    total_profit DESC;
