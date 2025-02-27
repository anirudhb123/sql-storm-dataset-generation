
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31' LIMIT 1)
        AND (SELECT d_date_sk FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31' ORDER BY d_date DESC LIMIT 1)
    GROUP BY 
        ws_item_sk
),
StoreSummary AS (
    SELECT 
        s_store_sk, 
        AVG(ss_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_dow IN (6, 0)) -- Only weekends
    GROUP BY 
        s_store_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr_customer_sk) AS unique_customers
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 60
    GROUP BY 
        sr_item_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state,
    SUM(ss.total_sales) AS total_sales,
    SUM(sr.total_return_amount) AS total_returns,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ss.avg_net_profit) AS store_avg_net_profit,
    COUNT(CASE WHEN cr.return_count > 0 THEN 1 END) AS items_with_returns
FROM 
    customer_address ca
LEFT JOIN 
    (SELECT 
        ws_item_sk, 
        SUM(ws_ext_sales_price) AS total_sales 
     FROM 
        web_sales 
     WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
     GROUP BY 
        ws_item_sk) ss ON ca.ca_address_sk = ss.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON ss.ws_item_sk = cr.sr_item_sk
LEFT JOIN 
    StoreSummary rem ON rem.s_store_sk = ca.ca_address_sk
WHERE 
    ca.ca_city IS NOT NULL 
AND 
    ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ss.total_sales) > 1000000
ORDER BY 
    total_sales DESC, total_returns ASC;
