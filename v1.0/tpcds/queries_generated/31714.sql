
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        cs_sold_date_sk,
        cs_item_sk,
        SUM(cs_quantity) + s.total_quantity_sold,
        SUM(cs_net_profit) + s.total_profit
    FROM 
        catalog_sales cs
    JOIN 
        sales_data s ON cs_sold_date_sk = s.ws_sold_date_sk AND cs_item_sk = s.ws_item_sk
    GROUP BY 
        cs_sold_date_sk, cs_item_sk
),
item_details AS (
    SELECT 
        i_item_sk, 
        i_product_name, 
        i_current_price, 
        COALESCE(AVG(ws_ext_sales_price), 0) AS avg_sales_price,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY 
        i_item_sk, i_product_name, i_current_price
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        SUM(sd.total_profit) AS customer_profit,
        COUNT(DISTINCT sd.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        sales_data sd ON ws.ws_item_sk = sd.ws_item_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    id.i_item_sk,
    id.i_product_name,
    id.i_current_price,
    id.avg_sales_price,
    cs.customer_profit,
    cs.unique_items_purchased,
    CASE 
        WHEN cs.customer_profit IS NULL THEN 'No Purchases'
        WHEN cs.customer_profit > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS customer_segment
FROM 
    item_details id
LEFT JOIN 
    customer_summary cs ON id.i_item_sk IN (SELECT unnest(ws_item_sk) FROM web_sales WHERE ws_bill_customer_sk = cs.c_customer_sk)
WHERE 
    id.total_returns > 0
ORDER BY 
    id.average_sales_price DESC, 
    cs.customer_profit DESC
LIMIT 100
OFFSET 0;
