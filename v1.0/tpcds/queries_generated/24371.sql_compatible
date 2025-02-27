
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE i.i_current_price IS NOT NULL 
      AND (p.p_discount_active = 'Y' OR p.p_promo_sk IS NULL)
    GROUP BY ws.web_site_sk
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        CASE 
            WHEN COUNT(DISTINCT c.c_customer_sk) > 50 THEN 'High'
            WHEN COUNT(DISTINCT c.c_customer_sk) BETWEEN 20 AND 50 THEN 'Medium'
            ELSE 'Low' 
        END AS customer_segment
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
),
HighProfitSales AS (
    SELECT 
        sd.web_site_sk,
        sd.total_quantity,
        sd.total_profit,
        ai.customer_segment
    FROM SalesData sd
    JOIN AddressInfo ai ON sd.web_site_sk = ai.ca_address_sk
    WHERE sd.total_profit > (SELECT AVG(total_profit) FROM SalesData) 
      AND ai.customer_segment = 'High'
)
SELECT 
    hps.web_site_sk,
    hps.total_quantity,
    hps.total_profit,
    ai.ca_city,
    ai.ca_state,
    CASE 
        WHEN hps.total_profit IS NULL THEN 'No Profit'
        WHEN hps.total_profit < 1000 THEN 'Low Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM HighProfitSales hps
FULL OUTER JOIN AddressInfo ai ON hps.web_site_sk = ai.ca_address_sk
ORDER BY hps.total_profit DESC NULLS LAST, ai.ca_city ASC;
