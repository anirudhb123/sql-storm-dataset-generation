
WITH enriched_sales AS (
    SELECT 
        ws.ws_order_number,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        ws.ws_sales_price,
        ws.ws_quantity,
        (ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY (ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
),
top_customers AS (
    SELECT 
        customer_id,
        c_first_name,
        c_last_name,
        SUM(total_sales) AS total_spent
    FROM 
        enriched_sales
    WHERE 
        sales_rank = 1
    GROUP BY 
        customer_id, c_first_name, c_last_name
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        tc.customer_id,
        tc.total_spent
    FROM 
        customer_demographics cd
    JOIN 
        top_customers tc ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = tc.customer_id)
)
SELECT 
    cd.customer_id,
    cd.total_spent,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    customer_demo cd
ORDER BY 
    cd.total_spent DESC
LIMIT 10;
