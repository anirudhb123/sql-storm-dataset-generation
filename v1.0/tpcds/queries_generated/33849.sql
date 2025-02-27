
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2022
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_pref_customer_flag,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ss.ws_order_number) AS order_count,
        SUM(ss.total_sales) AS total_sales
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        sales_summary AS ss ON c.c_customer_sk = ss.web_site_sk
    GROUP BY 
        c.c_customer_sk, c.c_pref_customer_flag, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        SUM(ca.order_count) AS total_orders,
        SUM(ca.total_sales) AS total_sales
    FROM 
        customer_analysis AS ca
    JOIN 
        customer_address AS ca ON ca.c_customer_sk = ca.c_customer_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
)
SELECT 
    t.ca_city,
    AVG(t.total_sales) AS avg_sales,
    MAX(t.total_orders) AS max_orders
FROM 
    top_customers AS t
WHERE 
    t.total_sales IS NOT NULL
GROUP BY 
    t.ca_city
HAVING 
    AVG(t.total_sales) > (SELECT AVG(total_sales) FROM top_customers)
ORDER BY 
    avg_sales DESC
LIMIT 10;
