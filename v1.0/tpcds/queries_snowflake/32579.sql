
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        1 AS level 
    FROM 
        item i 
    WHERE 
        i.i_item_sk IS NOT NULL
    UNION ALL
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        CONCAT(ih.i_item_desc, ' -> ', i.i_item_desc) AS i_item_desc,
        ih.level + 1 AS level
    FROM 
        ItemHierarchy ih
    JOIN 
        item i ON i.i_item_sk = (ih.i_item_sk + 1) 
    WHERE 
        ih.level < 5
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
DemographicsData AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ih.i_item_id,
    ih.i_item_desc,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.order_count, 0) AS order_count,
    dd.customer_count AS total_customers,
    dd.avg_purchase_estimate
FROM 
    ItemHierarchy ih
LEFT JOIN 
    SalesData sd ON ih.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    DemographicsData dd ON dd.customer_count > 0 
ORDER BY 
    ih.level, total_profit DESC
LIMIT 100;
