
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sale_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
HighProfitSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.ws_order_number,
        sd.ws_net_profit,
        ca.ca_city,
        COUNT(DISTINCT ws.ws_order_number) OVER (PARTITION BY ca.ca_city) AS total_orders_in_city
    FROM SalesData sd
    JOIN item i ON sd.ws_item_sk = i.i_item_sk
    LEFT JOIN customer c ON i.i_item_sk = c.c_current_hdemo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE sd.profit_rank <= 5
),
AggregatedSales AS (
    SELECT 
        ca.ca_city,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_profit) AS avg_profit_per_order
    FROM HighProfitSales hps
    JOIN customer_address ca ON hps.ca_city = ca.ca_city
    GROUP BY ca.ca_city
)
SELECT 
    city,
    total_profit,
    avg_profit_per_order,
    CASE 
        WHEN total_profit >= 10000 THEN 'High Profit'
        WHEN total_profit >= 5000 THEN 'Medium Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM AggregatedSales
ORDER BY total_profit DESC
LIMIT 10;
