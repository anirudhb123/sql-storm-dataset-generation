
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cs.total_quantity,
        cs.total_sales_amount,
        cs.total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_sales_amount DESC) AS rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN customer_sales cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cs.total_sales_amount > (
            SELECT AVG(total_sales_amount) FROM customer_sales
        )
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        hc.hd_income_band_sk
    FROM 
        customer c
        JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN household_demographics hc ON c.c_current_hdemo_sk = hc.hd_demo_sk
)
SELECT 
    ci.c_customer_id,
    ci.ca_city,
    ci.ca_state,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_credit_rating,
    hvc.total_quantity,
    hvc.total_sales_amount,
    hvc.total_orders
FROM 
    customer_info ci
    JOIN high_value_customers hvc ON ci.c_customer_sk = hvc.c_customer_sk
WHERE 
    ci.ca_state IN ('NY', 'CA')
ORDER BY 
    hvc.total_sales_amount DESC
LIMIT 100;
