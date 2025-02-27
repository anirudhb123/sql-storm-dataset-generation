
WITH RECURSIVE revenue_analysis AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), top_items AS (
    SELECT 
        ra.ws_item_sk,
        ra.total_revenue,
        ra.total_orders,
        i.i_item_desc,
        i.i_current_price
    FROM 
        revenue_analysis ra
    JOIN 
        item i ON ra.ws_item_sk = i.i_item_sk
    WHERE 
        ra.rank <= 10
), customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk
)
SELECT 
    ca.c_customer_sk,
    ca.cd_gender,
    ca.cd_income_band_sk,
    ca.total_orders,
    ca.total_spent,
    ti.total_revenue,
    ti.total_orders AS item_orders,
    i.i_item_desc,
    i.i_current_price
FROM 
    customer_analysis ca
LEFT JOIN 
    top_items ti ON ca.total_orders > 0
LEFT JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    ca.cd_income_band_sk IS NOT NULL
ORDER BY 
    ca.total_spent DESC, ti.total_revenue DESC;
