
WITH RankedSales AS (
    SELECT 
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        RANK() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_net_profit DESC) AS rank_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) AND (SELECT MAX(d.d_date_sk) FROM date_dim d)
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_item_sk) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
),
MaxReturn AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_return_amt
    FROM 
        CustomerReturns cr
    WHERE 
        cr.total_return_amt = (SELECT MAX(total_return_amt) FROM CustomerReturns)
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cs.cs_ship_customer_sk) AS unique_customers,
    SUM(cs.cs_net_profit) AS total_profit,
    COALESCE(MAX(mr.total_return_amt), 0) AS max_return_amount
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
LEFT JOIN 
    MaxReturn mr ON c.c_customer_sk = mr.sr_customer_sk
INNER JOIN 
    RankedSales rs ON cs.ss_item_sk = rs.ss_item_sk AND rs.rank_profit = 1
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT cs.cs_ship_customer_sk) > 5 
AND 
    SUM(cs.cs_net_profit) > 1000
ORDER BY 
    total_profit DESC, ca.ca_state ASC;
