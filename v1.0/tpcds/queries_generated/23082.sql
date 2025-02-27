
WITH RankedSales AS (
    SELECT 
        cs.c_line_number,
        cs.cs_sales_price,
        cs.cs_order_number,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_sales_price DESC) AS rn,
        SUM(cs.cs_sales_price * cs.cs_quantity) OVER (PARTITION BY cs.cs_order_number) AS total_order_value
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3) 
        AND d.d_dow NOT IN (0, 6)
    )
    AND cs.cs_sales_price > (SELECT AVG(ws.ws_sales_price) FROM web_sales ws)
),
InventoryStatus AS (
    SELECT 
        inv.inv_quantity_on_hand,
        inv.inv_item_sk,
        (CASE 
            WHEN inv.inv_quantity_on_hand IS NULL THEN 'Out of Stock'
            WHEN inv.inv_quantity_on_hand = 0 THEN 'No Inventory'
            ELSE 'Available'
         END) AS inventory_status
    FROM inventory inv
    WHERE inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk 
    WHERE cd.cd_gender IS NOT NULL
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    r.rn,
    r.cs_sales_price,
    r.cs_quantity,
    r.total_order_value,
    i.inv_quantity_on_hand,
    i.inventory_status,
    c.cd_gender,
    c.customer_count,
    CASE 
        WHEN c.avg_purchase_estimate IS NULL THEN 'Estimate Not Available'
        WHEN c.avg_purchase_estimate < 1000 THEN 'Low Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_classification
FROM RankedSales r
LEFT JOIN InventoryStatus i ON r.cs_order_number = i.inv_item_sk
LEFT JOIN CustomerDemographics c ON r.cs_order_number = c.cd_demo_sk
WHERE r.total_order_value > 1000
ORDER BY r.total_order_value DESC, r.cs_sales_price DESC;
