
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023) - 90 
                                AND (SELECT MAX(d.d_date_sk) FROM date_dim AS d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        ss.total_sales,
        ss.average_profit,
        ss.order_count
    FROM 
        sales_summary AS ss
    JOIN 
        customer AS c ON c.c_customer_id = ss.c_customer_id
    WHERE 
        ss.sales_rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.average_profit,
    tc.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    ca.ca_city,
    ca.ca_state
FROM 
    top_customers AS tc
JOIN 
    customer_demographics AS cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    customer_address AS ca ON ca.ca_address_sk = c.c_current_addr_sk
ORDER BY 
    tc.total_sales DESC;
