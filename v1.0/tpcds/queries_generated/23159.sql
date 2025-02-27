
WITH RankedWebSales AS (
    SELECT 
        ws_customer_sk, 
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY ws_sales_price DESC) AS rank,
        SUM(ws_sales_price) OVER (PARTITION BY ws_customer_sk) AS total_spent
    FROM web_sales
    WHERE ws_sales_price IS NOT NULL
), 
ReturnDetails AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt_inc_tax) AS total_returned,
        COUNT(wr_order_number) AS return_count
    FROM web_returns
    WHERE wr_return_amt_inc_tax IS NOT NULL
    GROUP BY wr_returning_customer_sk
), 
CombinedResults AS (
    SELECT 
        cw.ws_customer_sk AS customer_sk,
        cw.ws_sales_price AS highest_price,
        cw.total_spent AS total_spent,
        COALESCE(rd.total_returned, 0) AS total_returned,
        COALESCE(rd.return_count, 0) AS return_count
    FROM RankedWebSales cw
    LEFT JOIN ReturnDetails rd ON cw.ws_customer_sk = rd.wr_returning_customer_sk
    WHERE cw.rank = 1
)
SELECT 
    c.c_customer_id, 
    ca.ca_address_id,
    cr.customer_sk,
    cr.highest_price,
    cr.total_spent,
    cr.total_returned,
    cr.return_count,
    CASE 
        WHEN cr.total_returned > cr.total_spent THEN 'Negative Value'
        ELSE COALESCE((cr.total_spent - cr.total_returned) / NULLIF(cr.total_spent, 0), 0) 
    END AS net_value_ratio
FROM CombinedResults cr
JOIN customer c ON cr.customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    cr.highest_price > 100 AND 
    (cr.total_spent > 0 OR cr.total_returned > 0)
ORDER BY net_value_ratio DESC;
