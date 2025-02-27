
WITH RecursiveSales AS (
    SELECT 
        ws.web_site_id,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.net_profit IS NOT NULL
),
AggregatedReturns AS (
    SELECT 
        sr_items.item_sk,
        SUM(sr.return_quantity) AS total_returned,
        SUM(sr.return_amt) AS total_return_amt
    FROM 
        store_returns sr
    JOIN 
        (SELECT 
            sr_item_sk, COUNT(DISTINCT sr_ticket_number) AS item_count
         FROM 
            store_returns 
         GROUP BY 
            sr_item_sk
         HAVING 
            COUNT(DISTINCT sr_ticket_number) > 1) AS sr_items
    ON 
        sr.item_sk = sr_items.sr_item_sk
    GROUP BY 
        sr_items.item_sk
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' AND cd_gender = 'F' THEN 'Married Female'
            WHEN cd_marital_status = 'M' AND cd_gender = 'M' THEN 'Married Male'
            ELSE 'Other'
        END AS marital_gender
    FROM 
        customer_demographics
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COALESCE(agr.total_returned, 0) AS total_returned_qty,
    cd.marital_gender,
    COUNT(CASE WHEN ws.ws_net_profit > 0 THEN 1 END) AS positive_profit_count,
    SUM(CASE 
            WHEN ws.ws_net_profit IS NULL THEN 1 
            ELSE 0 
        END) AS null_profit_count
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    AggregatedReturns agr ON ws.ws_item_sk = agr.item_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_city IS NOT NULL AND
    (ws.ws_net_profit IS NOT NULL OR agr.total_return_amt > 100)
GROUP BY 
    c.c_customer_id,
    ca.ca_city,
    cd.marital_gender
HAVING 
    SUM(ws.ws_net_profit) > 5000
ORDER BY 
    total_net_profit DESC;
