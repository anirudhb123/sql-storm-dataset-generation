
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS Level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.Level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS Total_Net_Profit,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS Profit_Rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2022
    GROUP BY ws.web_site_sk
),
HighProfitSites AS (
    SELECT web_site_sk, Total_Net_Profit, Total_Orders
    FROM SalesSummary
    WHERE Profit_Rank <= 5
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS Customer_Count,
    COALESCE(ROUND(AVG(cd.cd_purchase_estimate), 2), 0) AS Average_Purchase_Estimate,
    SUM(CASE 
            WHEN ws.ws_ext_sales_price IS NULL THEN 0 
            ELSE ws.ws_ext_sales_price 
        END) AS Total_Sales,
    i.i_item_desc AS Top_Item_Description
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN HighProfitSites hps ON ws.ws_web_site_sk = hps.web_site_sk
WHERE ca.ca_state = 'CA'
GROUP BY ca.ca_city, i.i_item_desc
HAVING COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY Total_Sales DESC, Customer_Count DESC;
