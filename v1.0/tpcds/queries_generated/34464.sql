
WITH RECURSIVE SalesDetails AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    UNION ALL
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit + sd.ws_net_profit AS ws_net_profit,
        sd.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesDetails sd ON ws.ws_order_number = sd.ws_order_number AND sd.level < 5
)

SELECT 
    COALESCE(da.d_dow, 'Unknown') AS weekday,
    SUM(sd.ws_net_profit) AS total_profit,
    AVG(sd.ws_sales_price) AS avg_sales_price,
    MAX(sd.ws_quantity) AS max_quantity_sold,
    COUNT(DISTINCT sd.ws_order_number) AS distinct_orders
FROM 
    SalesDetails sd
LEFT JOIN 
    date_dim da ON da.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '1 day')
GROUP BY 
    da.d_dow
HAVING 
    total_profit > 1000
ORDER BY 
    total_profit DESC;

SELECT 
    'Total Returns' AS return_type,
    COUNT(cr_order_number) AS total_returns,
    SUM(cr_return_amount) AS total_return_amount
FROM 
    catalog_returns
WHERE 
    cr_returned_date_sk IN (
        SELECT 
            d_date_sk 
        FROM 
            date_dim 
        WHERE 
            d_date BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE
    )
UNION ALL
SELECT 
    'Total Store Sales' AS return_type,
    COUNT(ss_ticket_number),
    SUM(ss_net_paid)
FROM 
    store_sales
WHERE 
    ss_sold_date_sk IN (
        SELECT 
            d_date_sk 
        FROM 
            date_dim 
        WHERE 
            d_date BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE
    )
ORDER BY 
    return_type;
