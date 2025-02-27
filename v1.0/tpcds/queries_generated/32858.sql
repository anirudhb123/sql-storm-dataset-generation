
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_marital_status,
        cd.cd_gender,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
top_sales AS (
    SELECT 
        si.item_desc,
        si.item_id,
        si.total_sales
    FROM 
        (SELECT 
            i.i_item_id, 
            i.i_item_desc, 
            s.total_sales 
        FROM 
            item i 
        INNER JOIN sales_cte s ON i.i_item_sk = s.ws_item_sk 
        WHERE 
            s.sales_rank <= 5) si
    ORDER BY 
        si.total_sales DESC
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    SUM(ws.ws_net_paid) AS total_spent,
    COUNT(ws.ws_order_number) AS order_count,
    ts.item_desc,
    ts.total_sales
FROM 
    web_sales ws
JOIN 
    customer_info ci ON ws.ws_ship_customer_sk = ci.c_customer_sk
LEFT JOIN 
    top_sales ts ON ts.item_id = ws.ws_item_sk
WHERE 
    ci.hd_income_band_sk IS NOT NULL
AND 
    ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) - 365 FROM date_dim)
GROUP BY 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ts.item_desc,
    ts.total_sales
HAVING 
    SUM(ws.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC;
