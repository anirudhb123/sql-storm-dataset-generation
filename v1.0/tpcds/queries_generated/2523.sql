
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        ws.web_site_sk, ws.web_name, ws.web_site_id
),
HighProfitSites AS (
    SELECT 
        web_site_sk,
        web_name,
        total_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank = 1
), 
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COALESCE(SUM(cr.total_return_value), 0) AS total_returns_value
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    HighProfitSites hps ON c.c_current_addr_sk = hps.web_site_sk 
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
WHERE 
    cd.cd_gender = 'F'
AND 
    cd.cd_marital_status = 'M'
AND 
    EXISTS (
        SELECT 1 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = c.c_customer_sk 
        AND ws.ws_net_profit > 0
    )
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 100
ORDER BY 
    num_customers DESC, total_returns_value DESC;
