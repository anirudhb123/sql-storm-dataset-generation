
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
filtered_sales_data AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        COALESCE(SUM(sr.return_quantity), 0) AS total_returns,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        sales_data sd
    LEFT JOIN 
        store_returns sr ON sd.ws_item_sk = sr.sr_item_sk
    GROUP BY 
        sd.ws_item_sk, sd.total_quantity, sd.total_profit
),
qualified_items AS (
    SELECT 
        fis.ws_item_sk,
        fis.total_quantity,
        fis.total_profit,
        fis.total_returns,
        fis.unique_customers,
        DENSE_RANK() OVER (ORDER BY fis.total_profit DESC) AS profit_rank
    FROM 
        filtered_sales_data fis
    WHERE 
        fis.total_profit > 1000 AND 
        fis.total_quantity > 100
),
top_items AS (
    SELECT 
        q.ws_item_sk,
        q.total_quantity,
        q.total_profit,
        q.total_returns,
        q.unique_customers
    FROM 
        qualified_items q
    WHERE 
        q.profit_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_profit,
    ti.total_returns,
    ti.unique_customers
FROM 
    top_items ti
JOIN 
    item i ON ti.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price NOT BETWEEN 5.00 AND 50.00
ORDER BY 
    ti.total_profit DESC;
