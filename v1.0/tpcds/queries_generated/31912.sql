
WITH RECURSIVE Sales_CTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_sales_price, ws_quantity, 1 AS Sale_Level
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)

    UNION ALL

    SELECT ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_sales_price, ws.ws_quantity + cte.ws_quantity, cte.Sale_Level + 1
    FROM web_sales ws
    JOIN Sales_CTE cte ON ws.ws_item_sk = cte.ws_item_sk
    WHERE cte.Sale_Level < 5
),
Item_Summary AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_quantity) AS total_sold,
        AVG(ws.net_profit) AS avg_profit
    FROM item i
    LEFT JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id, i.i_item_desc
),
Customer_Demo AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           COUNT(c.c_customer_sk) AS customer_count,
           SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    i.i_item_desc,
    isum.total_sold,
    isum.avg_profit,
    cdemo.cd_gender,
    cdemo.customer_count,
    cdemo.total_spent
FROM Item_Summary isum
JOIN Customer_Demo cdemo ON cdemo.total_spent > 1000
LEFT JOIN Sales_CTE scte ON isum.i_item_sk = scte.ws_item_sk
WHERE isum.total_sold > 50
ORDER BY cdemo.total_spent DESC, isum.total_sold DESC;
