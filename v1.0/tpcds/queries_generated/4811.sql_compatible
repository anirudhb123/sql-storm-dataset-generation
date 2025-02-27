
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_qty) AS total_return_qty,
        SUM(wr.return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.store_sk,
        SUM(ss.net_paid) AS total_net_paid,
        COUNT(ss.ticket_number) AS total_sales_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.store_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    COALESCE(SUM(cs.total_return_qty), 0) AS total_return_qty,
    COALESCE(SUM(cs.total_return_amt), 0) AS total_return_amt,
    COALESCE(SUM(sss.total_net_paid), 0) AS total_net_paid,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY COALESCE(SUM(sss.total_net_paid), 0) DESC) AS city_rank
FROM 
    customer_address ca
LEFT JOIN
    CustomerReturns cs ON ca.ca_address_sk = cs.returning_customer_sk
LEFT JOIN 
    StoreSalesSummary sss ON ca.ca_address_sk = sss.store_sk
WHERE 
    ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca.ca_city, 
    ca.ca_state
HAVING 
    COALESCE(SUM(sss.total_net_paid), 0) > 1000
ORDER BY 
    city_rank;
