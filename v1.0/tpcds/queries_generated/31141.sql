
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales.total_net_profit,
        sales.order_count,
        DENSE_RANK() OVER (ORDER BY sales.total_net_profit DESC) AS sales_rank
    FROM 
        sales_data sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
), 
customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(ws.ws_order_number) AS purchase_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cust.c_customer_id,
    cust.c_first_name,
    cust.c_last_name,
    dem.cd_gender,
    dem.cd_marital_status,
    sd.i_product_name,
    sd.total_net_profit,
    cust.purchase_count,
    cust.total_spent
FROM 
    customer_details cust
JOIN 
    top_sales sd ON cust.purchase_count > 0 AND cust.total_spent > 1000
LEFT JOIN 
    (SELECT wp.wp_web_page_id, wp.wp_url FROM web_page wp WHERE wp.wp_char_count > 100) wp ON wp.wp_web_page_id = sd.i_item_id
WHERE 
    sd.sales_rank <= 10
ORDER BY 
    cust.total_spent DESC, cust.c_last_name ASC;
