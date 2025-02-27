
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY ws.web_site_sk, ws_sold_date_sk, ws_item_sk
),
ReturnStats AS (
    SELECT 
        wr.web_site_sk,
        COUNT(wr_returned_quantity) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM web_returns wr
    GROUP BY wr.web_site_sk
),
CityStats AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_city
),
SalesAndReturns AS (
    SELECT 
        ws.web_site_sk,
        COALESCE(rs.total_quantity, 0) AS total_quantity,
        COALESCE(rs.total_net_profit, 0) AS total_net_profit,
        COALESCE(rs_total_returns.total_returns, 0) AS total_returns,
        COALESCE(rs_total_returns.total_return_amount, 0) AS total_return_amount
    FROM RankedSales rs
    FULL OUTER JOIN ReturnStats rs_total_returns ON rs.web_site_sk = rs_total_returns.web_site_sk
)
SELECT 
    s.web_site_sk,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_net_profit, 0) AS total_net_profit,
    COALESCE(s.total_returns, 0) AS total_returns,
    s.total_return_amount,
    cs.total_customers
FROM SalesAndReturns s
JOIN CityStats cs ON s.web_site_sk = cs.total_customers
WHERE s.total_net_profit > 1000
ORDER BY total_net_profit DESC
LIMIT 50;
