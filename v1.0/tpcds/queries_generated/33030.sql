
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
top_selling_items AS (
    SELECT 
        item_sk,
        total_quantity,
        total_profit
    FROM 
        sales_summary
    WHERE 
        rank <= 10
),
date_range AS (
    SELECT 
        d.d_date,
        d.d_day_name 
    FROM 
        date_dim d 
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    d.d_day_name,
    COALESCE(SUM(ts.total_quantity), 0) AS total_quantity,
    COALESCE(SUM(ts.total_profit), 0) AS total_profit,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers
FROM 
    date_range d
LEFT JOIN 
    top_selling_items ts ON ts.item_sk IN (
        SELECT 
            ws.ws_item_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_sold_date_sk = d.d_date
    )
LEFT JOIN 
    customer_data cd ON cd.c_customer_sk IN (
        SELECT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_sold_date_sk = d.d_date AND ws.ws_item_sk = ts.item_sk
    )
GROUP BY 
    d.d_day_name
ORDER BY 
    d.d_day_name;
