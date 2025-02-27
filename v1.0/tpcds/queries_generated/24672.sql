
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    GROUP BY ws.sold_date_sk, ws.item_sk
),
Aggregated_Sales AS (
    SELECT 
        sc.sold_date_sk,
        sc.item_sk,
        sc.total_net_profit,
        sc.total_orders,
        SUM(sc.total_net_profit) OVER (PARTITION BY sc.sold_date_sk) AS daily_total_profit,
        SUM(sc.total_orders) OVER (PARTITION BY sc.sold_date_sk) AS daily_total_orders
    FROM Sales_CTE sc
    WHERE sc.rank <= 10
),
Top_Sales AS (
    SELECT 
        ag.sold_date_sk,
        ag.item_sk,
        ag.total_net_profit,
        ag.daily_total_profit,
        ag.daily_total_orders,
        CASE 
            WHEN ag.total_net_profit = 0 THEN 'No Profit'
            WHEN ag.total_net_profit / NULLIF(ag.daily_total_profit, 0) > 0.5 THEN 'High Contribution'
            ELSE 'Low Contribution'
        END AS contribution_category
    FROM Aggregated_Sales ag
)
SELECT 
    d.d_date,
    ts.item_sk,
    ts.total_net_profit,
    ts.daily_total_profit,
    ts.daily_total_orders,
    ts.contribution_category,
    COALESCE((SELECT COUNT(*)
              FROM store_sales ss
              WHERE ss.ss_sold_date_sk = ts.sold_date_sk AND ss.ss_item_sk = ts.item_sk), 0) AS total_store_sales,
    COALESCE((SELECT COUNT(*)
              FROM catalog_sales cs
              WHERE cs.cs_sold_date_sk = ts.sold_date_sk AND cs.cs_item_sk = ts.item_sk), 0) AS total_catalog_sales,
    CASE
        WHEN ts.daily_total_orders > 100 THEN 'Popular Item'
        WHEN ts.daily_total_orders IS NULL THEN 'No Orders'
        ELSE 'Average Item'
    END AS popularity
FROM Top_Sales ts
JOIN date_dim d ON ts.sold_date_sk = d.d_date_sk
WHERE d.d_year = 2023
ORDER BY ts.total_net_profit DESC, d.d_date DESC;
