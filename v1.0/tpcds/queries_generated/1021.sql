
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS orders_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
    HAVING 
        SUM(ws.ws_quantity) > 100
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        cs.total_spent,
        ROW_NUMBER() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_summary cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
)
SELECT 
    hv.c_customer_sk,
    hv.total_spent,
    pi.i_product_name,
    pi.total_sales
FROM 
    high_value_customers hv
JOIN 
    customer_summary cs ON hv.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    popular_items pi ON pi.total_sales = (
        SELECT MAX(total_sales) 
        FROM popular_items 
        WHERE i_item_sk IN (
            SELECT ws.ws_item_sk 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk = cs.c_customer_sk
        )
    )
WHERE 
    cs.orders_count > 5
ORDER BY 
    hv.total_spent DESC, pi.total_sales DESC;
