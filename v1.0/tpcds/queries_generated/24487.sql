
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2)
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(cr.return_quantity) AS total_returns,
        SUM(cr.return_amt_inc_tax) AS total_return_amt
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
    HAVING 
        COUNT(cr.return_quantity) > 5
),
SalesWithReturns AS (
    SELECT 
        r.web_site_sk,
        r.ws_order_number,
        r.ws_sales_price,
        r.ws_net_profit,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amt, 0) AS total_return_amt
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns c ON r.ws_order_number = c.returning_customer_sk
)
SELECT 
    s.web_site_sk,
    SUM(s.ws_sales_price) AS total_sales,
    SUM(s.total_returns) AS total_returns,
    AVG(CASE WHEN s.total_return_amt IS NULL THEN 0 ELSE s.total_return_amt END) AS average_return_amount,
    COUNT(s.ws_order_number) AS order_count,
    MAX(s.ws_net_profit) AS max_profit
FROM 
    SalesWithReturns s
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = s.web_site_sk)
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    s.web_site_sk
HAVING 
    SUM(s.ws_sales_price) > 10000 OR COUNT(s.ws_order_number) > 50
ORDER BY 
    total_sales DESC, max_profit ASC
FETCH FIRST 10 ROWS ONLY;
