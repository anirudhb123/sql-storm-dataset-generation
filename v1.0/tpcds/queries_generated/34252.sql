
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_profit,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_units_sold
    FROM 
        item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN sales_summary ws ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name, i.i_current_price
),
customer_analytics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_demo_sk IS NOT NULL THEN 'Active'
            ELSE 'Inactive'
        END AS customer_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
    HAVING 
        COUNT(DISTINCT ws.ws_order_number) > 0
)
SELECT 
    d.d_date,
    COUNT(DISTINCT ca.c_customer_id) AS active_customers,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ISNULL(id.total_profit, 0)) AS total_profit,
    AVG(id.i_current_price) AS average_item_price,
    SUM(CASE WHEN ca.customer_status = 'Active' THEN 1 ELSE 0 END) AS active_customer_count
FROM 
    date_dim d
LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
LEFT JOIN item_details id ON ws.ws_item_sk = id.i_item_sk
LEFT JOIN customer_analytics ca ON ws.ws_bill_customer_sk = ca.c_customer_id
WHERE 
    d.d_year = 2023 AND 
    (ca.cd_gender = 'M' OR ca.cd_marital_status = 'S')
GROUP BY 
    d.d_date
ORDER BY 
    d.d_date DESC
LIMIT 100;
