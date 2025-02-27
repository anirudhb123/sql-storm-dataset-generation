
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rn,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 2000
),
MonthlyProfits AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
    GROUP BY 
        d.d_year
)
SELECT 
    ca.ca_state,
    COALESCE(m.total_profit, 0) AS yearly_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(RANKED.ws_net_profit) AS average_net_profit
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    RankedSales RANKED ON RANKED.web_site_sk = c.c_current_cdemo_sk
LEFT JOIN 
    MonthlyProfits m ON m.d_year = YEAR(CURRENT_DATE) - 1
GROUP BY 
    ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    yearly_profit DESC,
    unique_customers ASC
LIMIT 10;
