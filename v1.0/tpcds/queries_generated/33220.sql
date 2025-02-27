
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit 
    FROM 
        web_sales 
    GROUP BY 
        ws_order_number, 
        ws_item_sk 
),
TimeFrame AS (
    SELECT 
        d_year, 
        d_month_seq, 
        d_dow,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2022 
    GROUP BY 
        d_year, d_month_seq, d_dow
),
ProfitableItems AS (
    SELECT 
        item.i_item_id, 
        item.i_item_desc, 
        SUM(ws.ws_net_profit) AS total_item_profit
    FROM 
        item 
    JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
    HAVING 
        total_item_profit > 1000
)
SELECT 
    c.c_customer_id,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
    MAX(total_item_profit) AS highest_item_profit,
    ROUND(AVG(total_quantity), 2) AS avg_quantity,
    STUFF((SELECT DISTINCT ',' + i_item_desc 
           FROM ProfitableItems 
           WHERE ProfitableItems.total_item_profit > 1000 
           FOR XML PATH('')), 1, 1, '') AS profitable_items
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    SalesCTE sc ON ws.ws_order_number = sc.ws_order_number
LEFT JOIN 
    ProfitableItems pi ON ws.ws_item_sk = pi.i_item_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1995 AND 
    (c.c_preferred_cust_flag IS NULL OR c.c_preferred_cust_flag = 'Y')
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_spent DESC;
