
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451009 AND 2451300
    GROUP BY 
        ws_item_sk
),
top_sales AS (
    SELECT
        item.i_item_id,
        item.i_product_name,
        sd.total_quantity,
        sd.total_profit,
        DENSE_RANK() OVER (ORDER BY sd.total_profit DESC) AS overall_rank
    FROM 
        sales_data sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.rank <= 5
)
SELECT 
    a.ca_city,
    a.ca_state,
    ts.i_item_id,
    ts.i_product_name,
    ts.total_quantity,
    ts.total_profit
FROM 
    customer_address a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    top_sales ts ON c.c_customer_sk = ts.ws_bill_customer_sk
WHERE 
    a.ca_city IS NOT NULL
    AND a.ca_state IN ('CA', 'NY')
    AND ts.total_profit IS NOT NULL
ORDER BY 
    a.ca_city ASC, 
    ts.total_profit DESC
LIMIT 100
UNION ALL
SELECT 
    'Total' AS ca_city,
    'Sales' AS ca_state,
    NULL AS i_item_id,
    NULL AS i_product_name,
    SUM(ts.total_quantity) AS total_quantity,
    SUM(ts.total_profit) AS total_profit
FROM 
    top_sales ts
HAVING 
    SUM(ts.total_profit) > 1000;
