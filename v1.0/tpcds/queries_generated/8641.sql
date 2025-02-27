
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws 
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk 
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231 
    GROUP BY ws.web_site_sk, ws_sold_date_sk
),
TopWebSites AS (
    SELECT web_site_sk, MAX(total_net_profit) AS max_net_profit
    FROM RankedSales
    WHERE profit_rank <= 5
    GROUP BY web_site_sk
),
CustomerAddressDetails AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE ca.ca_state IN (SELECT DISTINCT w.web_state FROM web_site w WHERE w.web_site_sk IN (SELECT web_site_sk FROM TopWebSites))
    GROUP BY ca.ca_city, ca.ca_state
)
SELECT 
    cads.ca_city,
    cads.ca_state,
    cads.unique_customers,
    tops.max_net_profit
FROM CustomerAddressDetails cads
JOIN TopWebSites tops ON cads.ca_state = (SELECT w.web_state FROM web_site w WHERE w.web_site_sk = tops.web_site_sk LIMIT 1);
