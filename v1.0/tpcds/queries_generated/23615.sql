
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws_inner.ws_sales_price) 
                             FROM web_sales ws_inner 
                             WHERE ws_inner.ws_ship_date_sk = ws.ws_ship_date_sk)
),

FilteredReturns AS (
    SELECT 
        wr.wr_order_number,
        COUNT(wr.wr_item_sk) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        RANK() OVER (PARTITION BY wr.wr_returning_customer_sk ORDER BY SUM(wr.wr_return_amt) DESC) AS return_rank
    FROM 
        web_returns wr 
    WHERE 
        wr.wr_return_quantity > 0
        AND EXISTS (SELECT 1 
                    FROM RankedSales r 
                    WHERE r.ws_order_number = wr.wr_order_number)
    GROUP BY 
        wr.wr_order_number,
        wr.wr_returning_customer_sk
)

SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(DISTINCT fs.ws_order_number) AS total_orders,
    SUM(COALESCE(fs.ws_net_profit, 0)) AS total_net_profit,
    SUM(fr.total_returns) AS total_returns,
    MAX(fr.total_return_amount) AS max_single_return_amount,
    MIN(CASE WHEN fr.return_rank = 1 THEN 'High Return Customer' ELSE 'Regular Customer' END) AS customer_type
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales fs ON c.c_customer_sk = fs.ws_order_number
LEFT JOIN 
    FilteredReturns fr ON fs.ws_order_number = fr.wr_order_number
GROUP BY 
    c.c_customer_id, 
    ca.ca_city
HAVING 
    SUM(COALESCE(fs.ws_net_profit, 0)) > 0 
    AND COUNT(DISTINCT fs.ws_order_number) > (SELECT COUNT(DISTINCT ws_inner.ws_order_number) 
                                                FROM web_sales ws_inner 
                                                WHERE ws_inner.ws_ship_date_sk = fs.ws_ship_date_sk) 
    AND MAX(fr.total_return_amount) IS NOT NULL
ORDER BY 
    total_net_profit DESC, 
    customer_type ASC;
