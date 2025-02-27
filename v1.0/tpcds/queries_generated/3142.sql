
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk
),
top_web_sites AS (
    SELECT 
        web_site_sk,
        total_sales,
        total_orders
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_addr_sk IS NOT NULL
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    w.w_warehouse_name,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_unique_orders,
    AVG(ci.total_spent) AS average_spent
FROM 
    warehouse w
LEFT JOIN 
    web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN 
    top_web_sites t ON ws.ws_web_site_sk = t.web_site_sk
LEFT JOIN 
    customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_id
WHERE 
    w.w_country = 'USA' 
    AND (ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231 OR ws.ws_sold_date_sk IS NULL)
GROUP BY 
    w.w_warehouse_name
ORDER BY 
    total_net_profit DESC
LIMIT 10;
