
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sold_date_sk, 
        ws.ws_quantity, 
        ws.ws_net_paid, 
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
high_value_items AS (
    SELECT 
        i.i_item_sk,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_sk
    HAVING 
        total_net_paid > 10000
),
customer_info AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_purchase_estimate
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ci.c_first_name, 
    ci.c_last_name, 
    ci.cd_gender, 
    COALESCE(rsi.sales_rank, 'Not Ranked') AS rank,
    hvi.total_net_paid,
    CASE 
        WHEN hvi.total_net_paid IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status
FROM 
    customer_info AS ci
LEFT JOIN 
    ranked_sales AS rsi ON ci.c_customer_sk = rsi.ws_order_number
LEFT JOIN 
    high_value_items AS hvi ON rsi.ws_item_sk = hvi.i_item_sk
WHERE 
    ci.cd_purchase_estimate IS NOT NULL
ORDER BY 
    ci.cd_purchase_estimate DESC, 
    hvi.total_net_paid DESC;
