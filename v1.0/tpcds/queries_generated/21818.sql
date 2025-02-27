
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk

    UNION ALL

    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales)
    GROUP BY 
        cs.cs_sold_date_sk, cs.cs_item_sk
),
sales_summary AS (
    SELECT 
        dd.d_date,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY sd.ws_item_sk ORDER BY sd.total_net_paid DESC) AS rank
    FROM
        sales_data sd
    JOIN 
        date_dim dd ON sd.ws_sold_date_sk = dd.d_date_sk
)
SELECT 
    s.s_store_id,
    s.s_store_name,
    COALESCE(ss.total_quantity, 0) AS total_sales,
    COALESCE(ss.total_net_paid, 0) AS total_revenue,
    (SELECT SUM(ws.sales_price) 
     FROM web_sales ws 
     WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_month_seq = (SELECT d_month_seq FROM date_dim WHERE d_date = CURRENT_DATE)))
     -
    (SELECT SUM(sr_return_qty) 
     FROM store_returns sr 
     WHERE sr_store_sk = s.s_store_sk 
     AND sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_month_seq = (SELECT d_month_seq FROM date_dim WHERE d_date = CURRENT_DATE))) AS total_gross
FROM 
    store s
LEFT JOIN 
    sales_summary ss ON s.s_store_sk = ss.ws_item_sk
WHERE 
    ss.rank = 1 OR ss.ws_item_sk IS NULL
ORDER BY 
    total_revenue DESC
LIMIT 10;
