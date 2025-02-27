
WITH RECURSIVE InventoryHierarchy AS (
    SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand 
    FROM inventory 
    WHERE inv_quantity_on_hand > 0
    UNION ALL
    SELECT i.inv_date_sk, i.inv_item_sk, i.inv_warehouse_sk, i.inv_quantity_on_hand 
    FROM inventory i
    JOIN InventoryHierarchy ih ON i.inv_item_sk = ih.inv_item_sk AND i.inv_warehouse_sk <> ih.inv_warehouse_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_income_band_sk,
           COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
RankedSales AS (
    SELECT sd.ws_item_sk,
           sd.total_sales,
           sd.total_net_profit,
           RANK() OVER (ORDER BY sd.total_net_profit DESC) AS profit_rank
    FROM SalesData sd
)
SELECT 
    ih.inv_date_sk,
    ih.inv_item_sk,
    SUM(ih.inv_quantity_on_hand) AS total_inventory,
    cs.total_sales,
    cs.total_net_profit,
    cd.customer_count,
    CASE 
        WHEN cd.customer_count IS NULL THEN 'No Customers'
        ELSE cd.customer_count::varchar 
    END AS customer_count_status,
    COALESCE(r.profit_rank, 'Not Ranked') AS sales_rank
FROM InventoryHierarchy ih
LEFT JOIN RankedSales r ON ih.inv_item_sk = r.ws_item_sk
LEFT JOIN SalesData cs ON ih.inv_item_sk = cs.ws_item_sk
LEFT JOIN CustomerDemographics cd ON cs.ws_item_sk = cd.cd_income_band_sk
WHERE ih.inv_quantity_on_hand > 100
  AND ih.inv_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
GROUP BY ih.inv_date_sk, ih.inv_item_sk, cs.total_sales, cs.total_net_profit, cd.customer_count, r.profit_rank
ORDER BY total_inventory DESC, total_net_profit DESC;
