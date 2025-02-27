
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 0 
            ELSE (ws.ws_sales_price - COALESCE(LAG(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price), 0)) 
        END AS price_difference
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_sales_price > 0
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns AS cr 
    WHERE 
        cr.cr_return_quantity > 0
    GROUP BY 
        cr.returning_customer_sk
),
ReturnStats AS (
    SELECT 
        cr.returning_customer_sk,
        COALESCE(SUM(cr.total_returns), 0) AS total_returned,
        SUM(CASE WHEN cr.total_return_amount > 1000 THEN 1 ELSE 0 END) AS high_value_returns
    FROM 
        CustomerReturns AS cr 
    GROUP BY 
        cr.returning_customer_sk
)
SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cs.ss_customer_sk) AS store_customers,
    COUNT(DISTINCT ws.ws_customer_sk) AS web_customers,
    SUM(CASE WHEN rs.sales_rank = 1 THEN rs.ws_sales_price ELSE 0 END) AS highest_sales_value,
    AVG(COALESCE(rs.price_difference, 0)) AS avg_price_change,
    rs.ws_item_sk AS item_sk,
    rs.ws_order_number AS order_number,
    r.returning_customer_sk,
    r.total_returned,
    r.high_value_returns
FROM 
    customer_address AS ca
LEFT JOIN 
    store_sales AS cs ON ca.ca_address_sk = cs.ss_store_sk
LEFT JOIN 
    web_sales AS ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
LEFT JOIN 
    RankedSales AS rs ON ws.ws_item_sk = rs.ws_item_sk AND ws.ws_order_number = rs.ws_order_number
LEFT JOIN
    ReturnStats AS r ON cs.ss_customer_sk = r.returning_customer_sk
WHERE 
    ca.ca_country = 'USA' AND
    (
        (ca.ca_state IN ('CA', 'NY') AND r.total_returned > 5)
        OR
        (ca.ca_city = 'Los Angeles' AND r.high_value_returns > 2)
    )
GROUP BY 
    ca.ca_address_sk, ca.ca_city, ca.ca_state, rs.ws_item_sk, rs.ws_order_number, r.returning_customer_sk
ORDER BY 
    highest_sales_value DESC, avg_price_change DESC
LIMIT 100;
