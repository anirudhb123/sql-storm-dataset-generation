
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
),
AggregateReturns AS (
    SELECT 
        sr.returning_customer_sk,
        SUM(sr.return_quantity) AS total_returned_quantity,
        SUM(sr.return_amt) AS total_returned_amount
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity IS NOT NULL
    GROUP BY 
        sr.returning_customer_sk
),
FinalMetrics AS (
    SELECT
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        COALESCE(SUM(rp.ws_net_profit), 0) AS total_profit,
        COALESCE(SUM(ar.total_returned_amount), 0) AS total_returns,
        AVG(DATEDIFF(DAY, c.c_birth_year, CURRENT_DATE)) AS avg_customer_age
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        RankedSales rp ON c.c_customer_sk = rp.web_site_sk
    LEFT JOIN 
        AggregateReturns ar ON c.c_customer_sk = ar.returning_customer_sk
    GROUP BY 
        ca.ca_country
)
SELECT 
    f.ca_country,
    f.total_customers,
    f.total_profit,
    f.total_returns,
    (f.total_profit - f.total_returns) AS net_profit,
    CASE 
        WHEN f.total_profit - f.total_returns < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    FinalMetrics f
WHERE 
    f.total_customers > 0
ORDER BY 
    net_profit DESC;
