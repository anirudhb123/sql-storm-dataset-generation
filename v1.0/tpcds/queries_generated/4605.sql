
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM web_sales ws
    WHERE ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 
                                WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_qty) AS total_returned,
        SUM(wr_return_amt_inc_tax) AS total_returned_amt
    FROM web_returns
    WHERE wr_returned_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY wr_returning_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cs.ss_customer_sk) AS total_customers,
    COALESCE(SUM(cr.total_returned), 0) AS total_returns,
    COALESCE(SUM(cs.ss_net_profit), 0) AS total_net_profit,
    SUM(CASE WHEN ws.ws_sales_price IS NULL THEN 1 ELSE 0 END) AS null_price_count
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN RankedSales rs ON rs.web_site_sk = c.c_current_addr_sk
WHERE ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(cs.ss_quantity) > 100
ORDER BY total_net_profit DESC;
