
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk >= 2451545 AND -- Approx. 2000-01-01
        ws.ws_sold_date_sk <= 2451545 + 365 -- One year period
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        web_name,
        total_net_profit,
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS website_rank
    FROM 
        SalesData
    WHERE 
        profit_rank <= 3 -- Top 3 performing web sites
)

SELECT 
    ca.ca_city,
    SUM(CASE 
            WHEN (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') THEN 1 
            ELSE 0 
        END) AS married_females_count,
    AVG(CASE 
            WHEN cd.cd_purchase_estimate IS NULL OR cd.cd_purchase_estimate < 0 THEN NULL 
            ELSE cd.cd_purchase_estimate 
        END) AS average_purchase_estimate,
    ARRAY_AGG(DISTINCT w.web_name) AS associated_websites
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    TopWebsites tw ON CASE 
                          WHEN c.c_birth_year IS NOT NULL AND c.c_birth_year < 1970 THEN 1
                          ELSE 0 
                      END = 1
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(c.c_customer_sk) > 10 AND 
    MAX(cd.cd_credit_rating) IS NOT NULL
ORDER BY 
    average_purchase_estimate DESC
LIMIT 5;
