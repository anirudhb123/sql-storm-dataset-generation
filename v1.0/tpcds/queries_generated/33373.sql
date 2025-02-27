
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales AS ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
    GROUP BY ws.web_site_sk, ws.web_name
), CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_spent,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS gender_rank
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING SUM(ws.ws_net_profit) > 1000
), AddressSummary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customers_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_address AS ca
    JOIN customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_state
), TopWebSites AS (
    SELECT 
        r.web_name,
        r.total_net_profit,
        ra.customers_count,
        r.order_count
    FROM SalesCTE r
    INNER JOIN AddressSummary ra ON ra.customers_count > 50
    WHERE r.rank <= 5
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.total_spent,
    tws.web_name,
    tws.total_net_profit,
    tws.customers_count
FROM CustomerInfo AS ci
JOIN TopWebSites AS tws ON ci.total_spent > 5000
ORDER BY ci.total_spent DESC, tws.total_net_profit DESC
LIMIT 10;
