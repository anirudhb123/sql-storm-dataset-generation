
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
income_bracket AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN 
        customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        hd.hd_demo_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    ss.c_first_name,
    ss.c_last_name,
    ss.total_sales,
    ss.total_orders,
    COALESCE(asum.customer_count, 0) AS customers_in_address,
    COALESCE(ib.customer_count, 0) AS customers_in_income_band,
    (SELECT COUNT(DISTINCT ws.ship_mode_sk)
     FROM web_sales ws
     WHERE ws.ws_bill_customer_sk = ss.c_customer_sk) AS distinct_ship_modes,
    (CASE 
         WHEN ss.total_sales IS NULL THEN 'No Sales' 
         WHEN ss.total_sales > 1000 THEN 'High Value Customer' 
         ELSE 'Regular Customer' 
     END) AS customer_type
FROM 
    sales_summary ss
LEFT JOIN 
    address_summary asum ON ss.c_customer_sk = asum.ca_address_sk
LEFT JOIN 
    income_bracket ib ON ss.c_customer_sk = ib.hd_demo_sk
WHERE 
    ss.rank <= 10
ORDER BY 
    ss.total_sales DESC;
