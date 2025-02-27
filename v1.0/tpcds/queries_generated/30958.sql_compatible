
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        (ca.ca_state IS NULL OR ca.ca_state = 'CA') 
        AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL) 
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city, ca.ca_state
),
high_value_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.total_orders,
        ci.total_spent,
        RANK() OVER (ORDER BY ci.total_spent DESC) AS customer_rank
    FROM 
        customer_info ci
    WHERE 
        ci.total_spent > (SELECT AVG(total_spent) FROM customer_info)
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.total_orders,
    ci.total_spent,
    COALESCE(rv.reason_description, 'No Reason') AS return_reason,
    s.total_sales AS item_sales
FROM 
    high_value_customers ci
LEFT JOIN 
    (SELECT 
         wr_returning_customer_sk,
         wr_return_reason_desc AS reason_description,
         COUNT(wr_return_number) AS return_count
     FROM 
         web_returns wr
     JOIN 
         reason r ON wr.wr_reason_sk = r.r_reason_sk
     GROUP BY 
         wr_returning_customer_sk, wr_return_reason_desc
    ) rv ON ci.c_customer_sk = rv.wr_returning_customer_sk
JOIN 
    (SELECT 
         ws_item_sk, 
         SUM(ws_sales_price) AS total_sales 
     FROM 
         web_sales 
     GROUP BY 
         ws_item_sk
    ) s ON s.ws_item_sk = (SELECT ws_item_sk FROM sales_cte WHERE rank = 1 LIMIT 1)
WHERE 
    ci.customer_rank <= 10
ORDER BY 
    ci.total_spent DESC;
