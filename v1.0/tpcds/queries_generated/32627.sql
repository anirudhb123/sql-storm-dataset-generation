
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 90 FROM date_dim) -- last 90 days
    GROUP BY ws_ship_date_sk, ws_item_sk
),
TopProfitableItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        c.c_customer_id,
        SUM(s.total_profit) AS total_profit
    FROM SalesCTE s
    JOIN item ON s.ws_item_sk = item.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = item.i_item_sk AND ws.ws_ship_date_sk = s.ws_ship_date_sk
    JOIN customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE s.rank_profit <= 5 -- Top 5 profitable items
    GROUP BY item.i_item_id, item.i_item_desc, c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    tpi.i_item_id,
    tpi.i_item_desc,
    cd.cd_gender,
    COUNT(DISTINCT tpi.c_customer_id) AS unique_customers,
    SUM(tpi.total_profit) AS total_profit,
    CASE 
        WHEN COUNT(DISTINCT tpi.c_customer_id) = 0 THEN 'No Customers'
        ELSE 'Has Customers'
    END AS customer_status
FROM TopProfitableItems tpi
JOIN CustomerDemographics cd ON tpi.c_customer_id = cd.cd_demo_sk
GROUP BY tpi.i_item_id, tpi.i_item_desc, cd.cd_gender
ORDER BY total_profit DESC
LIMIT 10 
UNION ALL 
SELECT 
    'Overall' AS i_item_id,
    NULL AS i_item_desc,
    NULL AS cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ws.ws_net_profit) AS total_profit
FROM customer c
JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim);
