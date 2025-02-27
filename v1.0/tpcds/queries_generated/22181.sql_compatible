
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        sr_return_quantity, 
        sr_return_amt, 
        sr_ticket_number,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_amt DESC) AS rnk
    FROM store_returns
    WHERE sr_return_amt IS NOT NULL
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 2000
    GROUP BY c.c_customer_sk
),
ReturnAnalysis AS (
    SELECT 
        r.ret_item_sk,
        SUM(r.ret_return_quantity) AS total_return_quantity,
        COALESCE(NULLIF(SUM(CASE WHEN r.ret_return_amt > 0 THEN r.ret_return_amt END), 0), 0) AS total_positive_return_amt
    FROM (
        SELECT 
            sr_item_sk AS ret_item_sk, 
            sr_return_quantity AS ret_return_quantity, 
            sr_return_amt AS ret_return_amt
        FROM store_returns
        WHERE sr_return_quantity > 0
    ) r
    GROUP BY r.ret_item_sk
)
SELECT 
    ca.ca_country,
    SUM(cs.total_profit) AS total_customer_profit,
    SUM(rr.total_return_quantity) AS total_returned,
    AVG(CASE WHEN rr.total_positive_return_amt > 0 THEN rr.total_positive_return_amt END) AS avg_positive_return_amt,
    COUNT(DISTINCT cs.c_customer_sk) AS active_customers
FROM customer_address ca
LEFT JOIN CustomerSales cs ON ca.ca_address_sk IN (
    SELECT c.c_current_addr_sk 
    FROM customer c 
    WHERE c.c_birth_month IS NOT NULL AND c.c_birth_day IS NOT NULL
)
LEFT JOIN ReturnAnalysis rr ON rr.ret_item_sk IN (
    SELECT DISTINCT ws.ws_item_sk 
    FROM web_sales ws 
    JOIN RankedReturns r ON r.sr_item_sk = ws.ws_item_sk
    WHERE r.rnk = 1
)
GROUP BY ca.ca_country
HAVING SUM(cs.total_profit) > (SELECT AVG(total_profit) FROM CustomerSales)
   AND COUNT(DISTINCT cs.c_customer_sk) > 10
ORDER BY ca.ca_country DESC;
