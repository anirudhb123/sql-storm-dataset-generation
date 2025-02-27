
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '1 year')
),
AvgPromotionProfit AS (
    SELECT 
        cp.cp_catalog_page_id,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM 
        catalog_page cp
    LEFT JOIN 
        catalog_returns cr ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    GROUP BY 
        cp.cp_catalog_page_id
),
ItemDemographics AS (
    SELECT 
        i.i_item_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        item i
    JOIN 
        customer_demographics cd ON i.i_item_sk = cd.cd_demo_sk
)
SELECT 
    ca.ca_city,
    SUM(rp.ws_net_profit) AS total_profit,
    COUNT(DISTINCT i.i_item_sk) AS unique_items_sold,
    AVG(cdp.avg_return_amount) AS average_return_per_promotion,
    MAX(i.cd_purchase_estimate) AS max_purchase_estimate,
    COUNT(CASE WHEN i.cd_gender = 'F' THEN 1 END) AS female_customers,
    COUNT(CASE WHEN i.cd_gender = 'M' THEN 1 END) AS male_customers
FROM 
    customer_address ca
JOIN 
    RankedSales rp ON ca.ca_address_sk = rp.ws_item_sk
JOIN 
    AvgPromotionProfit cdp ON rp.ws_item_sk = cdp.cp_catalog_page_id
JOIN 
    ItemDemographics i ON rp.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND rp.rn = 1
GROUP BY 
    ca.ca_city
HAVING 
    SUM(rp.ws_net_profit) > (SELECT AVG(ws.ws_net_profit) FROM web_sales ws)
ORDER BY 
    total_profit DESC;
