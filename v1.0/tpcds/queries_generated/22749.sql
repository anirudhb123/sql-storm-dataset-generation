
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk, 
        ws_sales_price,
        ws_net_paid,
        ws_net_profit,
        ws_quantity,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM 
        web_sales
    WHERE
        ws_net_paid > 100
),
AggregatedData AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_net_profit) AS total_net_profit,
        SUM(sd.ws_quantity) AS total_quantity,
        AVG(sd.ws_sales_price) AS avg_sales_price
    FROM 
        SalesData sd
    GROUP BY 
        sd.ws_item_sk
),
HighestProfitableItems AS (
    SELECT 
        ad.ws_item_sk,
        ad.total_net_profit,
        ad.total_quantity,
        ad.avg_sales_price,
        ntile(5) OVER (ORDER BY ad.total_net_profit DESC) AS profitability_scale
    FROM 
        AggregatedData ad
    WHERE 
        ad.total_quantity > (SELECT AVG(total_quantity) FROM AggregatedData)
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    sm.sm_carrier,
    ROUND(SUM(ss.ss_net_paid), 2) AS total_spent,
    MAX(hpi.profitability_scale) AS market_position
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    ship_mode sm ON ss.ss_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN 
    HighestProfitableItems hpi ON ss.ss_item_sk = hpi.ws_item_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND hpi.total_net_profit IS NOT NULL
    AND ss.ss_sold_date_sk = (
        SELECT MAX(ss2.ss_sold_date_sk) 
        FROM store_sales ss2 
        WHERE ss2.ss_customer_sk = c.c_customer_sk
    )
GROUP BY 
    c.c_customer_id, ca.ca_city, sm.sm_carrier
ORDER BY 
    total_spent DESC
FETCH FIRST 10 ROWS ONLY;
