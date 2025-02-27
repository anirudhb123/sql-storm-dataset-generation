
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i_category_id, i_category, NULL AS parent_category_id
    FROM item
    WHERE i_category_id IS NOT NULL
    
    UNION ALL
    
    SELECT i.category_id, i.category, ch.i_category_id
    FROM item i
    JOIN CategoryHierarchy ch ON i.category_id = ch.i_category_id
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY ws.ws_item_sk
),
TopSales AS (
    SELECT ws_item_sk, total_sales, avg_net_profit, total_orders
    FROM SalesData
    WHERE sales_rank <= 10
)
SELECT 
    th.i_category_id,
    th.i_category,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ts.avg_net_profit, 0) AS avg_net_profit,
    COALESCE(ts.total_orders, 0) AS total_orders
FROM 
    CategoryHierarchy th
LEFT JOIN TopSales ts ON th.i_category_id = ts.ws_item_sk
WHERE 
    th.parent_category_id IS NULL OR th.parent_category_id IN (SELECT DISTINCT i_category_id FROM item WHERE i_category_id IS NOT NULL)
ORDER BY total_sales DESC NULLS LAST;
