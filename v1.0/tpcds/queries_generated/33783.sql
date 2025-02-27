
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
customer_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        SUM(CASE 
                WHEN ws.ws_ext_sales_price IS NULL THEN 0 
                ELSE ws.ws_ext_sales_price 
            END) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state, cd.cd_gender
),
top_customers AS (
    SELECT 
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.total_spent,
        DENSE_RANK() OVER (PARTITION BY ci.ca_city, ci.ca_state ORDER BY ci.total_spent DESC) AS customer_rank
    FROM 
        customer_info ci
)
SELECT 
    ss.web_site_sk,
    ss.total_sales,
    ss.total_orders,
    tc.ca_city,
    tc.ca_state,
    tc.cd_gender,
    tc.total_spent
FROM 
    sales_summary ss
JOIN 
    top_customers tc ON ss.sales_rank = 1
WHERE 
    tc.customer_rank <= 10
ORDER BY 
    ss.total_sales DESC, tc.total_spent DESC;
