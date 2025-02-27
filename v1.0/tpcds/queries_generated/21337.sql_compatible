
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate
    FROM customer_stats cs
    WHERE cs.purchase_rank <= 5
),
location_stats AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN top_customers cs ON cs.c_customer_sk = c.c_customer_sk
    GROUP BY ca.ca_address_sk, ca.ca_city
),
sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS item_profit_rank
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
final_report AS (
    SELECT 
        ls.ca_city,
        sd.ws_item_sk,
        sd.total_sold,
        sd.total_profit,
        sd.total_net_paid,
        CASE 
            WHEN sd.total_net_paid IS NULL THEN 'N/A'
            ELSE ROUND(sd.total_net_paid / NULLIF(sd.total_sold, 0), 2) 
        END AS avg_net_per_item,
        CASE 
            WHEN sd.item_profit_rank = 1 THEN 'Top Performer'
            ELSE 'Regular'
        END AS item_status
    FROM location_stats ls
    LEFT JOIN sales_data sd ON ls.customer_count > 0 AND sd.total_profit > 1000
)
SELECT 
    fr.ca_city,
    fr.ws_item_sk,
    fr.total_sold,
    fr.total_profit,
    fr.avg_net_per_item,
    fr.item_status
FROM final_report fr
WHERE fr.total_sold > 0 
  AND fr.avg_net_per_item IS NOT NULL
ORDER BY fr.total_profit DESC, fr.ca_city ASC;
