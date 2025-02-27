
WITH RankedSales AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer_demographics
    WHERE cd_purchase_estimate IS NOT NULL
), 
HighSpenders AS (
    SELECT 
        rs.ws_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        rs.total_sales,
        rs.order_count
    FROM RankedSales rs
    JOIN CustomerDemographics cd ON rs.ws_customer_sk = cd.cd_demo_sk
    WHERE rs.sales_rank <= 10
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_id,
        w.w_warehouse_name,
        COUNT(distinct i.i_item_sk) AS item_count,
        AVG(i.i_current_price) AS avg_item_price
    FROM warehouse w
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY w.w_warehouse_id, w.w_warehouse_name
)
SELECT 
    hs.ws_customer_sk,
    hs.cd_gender,
    hs.cd_marital_status,
    hs.cd_education_status,
    hw.w_warehouse_name,
    hw.item_count,
    hw.avg_item_price,
    hs.total_sales,
    CASE 
        WHEN hs.order_count > 5 THEN 'Frequent Shopper'
        WHEN hs.total_sales > 1000 THEN 'High Roller'
        ELSE 'Occasional Buyer'
    END AS customer_tier
FROM HighSpenders hs
LEFT JOIN WarehouseInfo hw ON hw.item_count > 5
WHERE hw.avg_item_price IS NOT NULL
ORDER BY hs.total_sales DESC, hs.ws_customer_sk;

```
