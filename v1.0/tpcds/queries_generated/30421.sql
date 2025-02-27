
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.net_loss) AS total_net_loss
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss.ss_order_number) AS order_count
    FROM 
        store_sales ss
    WHERE 
        ss.ss_list_price > 100
    GROUP BY 
        ss.ss_store_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    SUM(ss.total_net_profit) AS overall_net_profit,
    AVG(CASE WHEN cs.total_return_quantity IS NOT NULL THEN cs.total_return_quantity ELSE 0 END) AS avg_return_quantity,
    MAX(de.d_year) AS max_sales_year
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    SalesCTE s ON c.c_customer_sk = s.ws_order_number
LEFT JOIN 
    CustomerReturns cs ON cs.returning_customer_sk = c.c_customer_sk
JOIN 
    date_dim de ON de.d_date_sk = s.ws_sold_date_sk
JOIN 
    StoreSalesSummary ss ON ss.ss_store_sk = c.c_current_hdemo_sk
WHERE 
    ca.ca_state = 'CA'
AND 
    (de.d_year BETWEEN 2022 AND 2023 OR de.d_year IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    overall_net_profit DESC;
