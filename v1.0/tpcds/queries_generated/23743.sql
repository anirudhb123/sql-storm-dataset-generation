
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_rec_start_date <= CURRENT_DATE)
    GROUP BY 
        ws.web_site_sk, 
        ws_item_sk
),
ProfitableItems AS (
    SELECT 
        ws_item_sk,
        web_site_sk,
        total_profit
    FROM 
        RankedSales
    WHERE 
        profit_rank <= 10
),
AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CASE 
            WHEN ca_city IS NULL THEN 'Unknown City'
            ELSE ca_city 
        END AS city_name
    FROM 
        customer_address
)
SELECT 
    ai.city_name,
    ai.ca_state,
    COUNT(DISTINCT pi.ws_item_sk) AS highly_profitable_item_count,
    SUM(pi.total_profit) AS total_high_profit
FROM 
    AddressInfo ai
LEFT JOIN 
    customer c ON ai.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    ProfitableItems pi ON c.c_current_cdemo_sk = pi.web_site_sk
GROUP BY 
    ai.ca_state, 
    ai.city_name
HAVING 
    SUM(pi.total_profit) IS NOT NULL 
    OR COUNT(DISTINCT pi.ws_item_sk) > 5
ORDER BY 
    total_high_profit DESC NULLS LAST
FETCH FIRST 20 ROWS ONLY;
