
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (
            SELECT 
                MAX(d.d_date_sk)
            FROM 
                date_dim d
            WHERE 
                d.d_year = 2023
        )
),
CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        SUM(wr.wr_return_quantity) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_returning_customer_sk
),
CustomerShipments AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        web_sales ws 
    GROUP BY 
        ws.ws_ship_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.s_ship_customer_sk) AS total_shippers,
    SUM(DISTINCT cs.total_spent) AS total_revenue,
    MAX(CASE WHEN cr.total_returned IS NOT NULL THEN cr.total_returned ELSE 0 END) AS max_returned,
    (SELECT COUNT(DISTINCT cd.cd_demo_sk)
     FROM customer_demographics cd
     WHERE cd.cd_gender = 'F') AS female_customers
FROM 
    customer_address ca
LEFT JOIN 
    CustomerShipments cs ON ca.ca_address_sk = cs.ws_ship_customer_sk
LEFT JOIN 
    CustomerReturns cr ON cr.wr_returning_customer_sk = cs.ws_ship_customer_sk
LEFT JOIN 
    RankedSales rs ON rs.web_site_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
HAVING 
    SUM(cs.total_spent) > 10000
ORDER BY 
    total_revenue DESC
LIMIT 10;
