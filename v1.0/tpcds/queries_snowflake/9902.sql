
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        ws.ws_ext_discount_amt > 0
    GROUP BY 
        c.c_customer_sk
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics AS cd
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer_sales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    JOIN 
        customer_demo AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk, 
    tc.total_sales, 
    tc.total_orders, 
    tc.cd_gender, 
    tc.cd_marital_status
FROM 
    top_customers AS tc
JOIN 
    customer_address AS ca ON ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = tc.c_customer_sk)
WHERE 
    ca.ca_state = 'CA'
ORDER BY 
    tc.total_sales DESC;
