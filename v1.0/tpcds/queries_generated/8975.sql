
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M' AND 
        cd.cd_purchase_estimate > 500
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        customer_sales.c_customer_id,
        customer_sales.total_sales,
        RANK() OVER (ORDER BY customer_sales.total_sales DESC) AS sales_rank
    FROM 
        customer_sales
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    cc.cc_name,
    s.s_store_name,
    sm.sm_type,
    d.d_year,
    d.d_month_seq
FROM 
    top_customers AS tc
JOIN 
    call_center AS cc ON cc.cc_call_center_sk = (SELECT cc_call_center_sk FROM call_center WHERE cc_mkt_id = (SELECT DISTINCT c.cc_mkt_id FROM customer AS c WHERE c.c_customer_id = tc.c_customer_id LIMIT 1))
JOIN 
    store AS s ON s.s_store_sk = (SELECT s_store_sk FROM store_sales WHERE ss_customer_sk = (SELECT c.c_customer_sk FROM customer AS c WHERE c.c_customer_id = tc.c_customer_id LIMIT 1) LIMIT 1)
JOIN 
    ship_mode AS sm ON sm.sm_ship_mode_sk = (SELECT ws_ship_mode_sk FROM web_sales WHERE ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer AS c WHERE c.c_customer_id = tc.c_customer_id LIMIT 1) LIMIT 1)
JOIN 
    date_dim AS d ON d.d_date_sk = (SELECT ws_sold_date_sk FROM web_sales WHERE ws_bill_customer_sk = (SELECT c.c_customer_sk FROM customer AS c WHERE c.c_customer_id = tc.c_customer_id LIMIT 1) LIMIT 1)
WHERE 
    tc.sales_rank <= 10;
