
WITH RECURSIVE Sales_Summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
Top_Profitable_Items AS (
    SELECT 
        ss_item_sk,
        total_profit,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS item_rank
    FROM 
        Sales_Summary
    WHERE 
        rank = 1
),
Customer_Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 'Unknown'
            ELSE 
                CASE 
                    WHEN cd_purchase_estimate < 1000 THEN 'Low'
                    WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
                    ELSE 'High'
                END 
        END AS purchase_estimate_band
    FROM 
        customer_demographics
)
SELECT 
    ca.city AS address_city,
    SUM(ws.total_quantity) AS total_qty_sold,
    SUM(ws.total_profit) AS total_profit,
    cd.gender,
    cd.marital_status,
    cd.purchase_estimate_band
FROM 
    Customer_Demographics cd
LEFT JOIN 
    (SELECT 
        ws.ws_item_sk,
        ss.total_quantity,
        ss.total_profit
    FROM 
        web_sales ws
    JOIN 
        Sales_Summary ss ON ws.ws_item_sk = ss.ws_item_sk) AS ws ON cd.cd_demo_sk = ws.ws_item_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT DISTINCT c.c_current_addr_sk FROM customer c WHERE c.c_current_cdemo_sk = cd.cd_demo_sk)
WHERE 
    cd.purchase_estimate_band <> 'Low'
GROUP BY 
    ca.city, cd.gender, cd.marital_status, cd.purchase_estimate_band
HAVING 
    total_profit > (SELECT AVG(total_profit) FROM Top_Profitable_Items WHERE item_rank <= 10)
ORDER BY 
    total_profit DESC;
