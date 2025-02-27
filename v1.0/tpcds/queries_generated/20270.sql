
WITH RankedSales AS (
    SELECT 
        ss_store_sk,
        ss_sold_date_sk,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        sr_return_quantity,
        SUM(sr_net_loss) OVER (PARTITION BY sr_customer_sk) AS total_loss,
        CASE 
            WHEN SUM(sr_net_loss) OVER (PARTITION BY sr_customer_sk) > 500 THEN 'High Loss'
            ELSE 'Low Loss'
        END AS loss_category
    FROM 
        store_returns
),
ProductPerformance AS (
    SELECT 
        ws_item_sk,
        AVG(ws_net_paid) AS avg_net_paid,
        MAX(ws_net_profit) AS max_net_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS customer_count,
    AVG(total_net_profit) AS avg_store_profit,
    MAX(total_loss) AS max_customer_loss,
    STRING_AGG(DISTINCT loss_category, ', ') AS combined_loss_category,
    ROUND(SUM(avg_net_paid) OVER (PARTITION BY loss_category), 2) AS avg_paid_by_loss_category
FROM 
    customer AS c
LEFT JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales AS rs ON rs.ss_store_sk = c.c_customer_sk
LEFT JOIN 
    CustomerReturns AS cr ON cr.sr_customer_sk = c.c_customer_sk
FULL OUTER JOIN 
    ProductPerformance AS pp ON pp.ws_item_sk = c.c_customer_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND (c.c_birth_year BETWEEN 1980 AND 1995 OR cr.sr_return_quantity IS NOT NULL)
GROUP BY 
    ca_city
HAVING 
    COUNT(DISTINCT c_customer_id) > 10
ORDER BY 
    ca_city,
    AVG(total_net_profit) DESC NULLS LAST;
