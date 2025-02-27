
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
ReturnsData AS (
    SELECT 
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_order_number, wr.wr_item_sk
),
CombinedSales AS (
    SELECT 
        sd.ws_order_number,
        sd.ws_item_sk,
        sd.ws_sales_price,
        sd.ws_quantity,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        sd.ws_net_profit - COALESCE(rd.total_return_amt, 0) AS net_profit_after_returns
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnsData rd ON sd.ws_order_number = rd.wr_order_number AND sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(cs.cs_net_profit) AS total_net_profit,
    AVG(cs.net_profit_after_returns) AS average_net_profit_after_returns,
    COUNT(DISTINCT CASE WHEN cs.rank_profit = 1 THEN cs.ws_order_number END) AS top_orders_count
FROM 
    CombinedSales cs
JOIN 
    customer c ON c.c_customer_sk = (SELECT c_customer_sk FROM web_sales WHERE ws_order_number = cs.ws_order_number LIMIT 1)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
HAVING 
    total_net_profit > (SELECT AVG(cs_net_profit) FROM CombinedSales)
ORDER BY 
    total_net_profit DESC;
