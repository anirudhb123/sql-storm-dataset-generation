
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2458834 AND 2458934 -- Date range
    GROUP BY ws_sold_date_sk, ws_item_sk
), RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(total_sales) AS total_sales_by_item
    FROM SalesData
    WHERE sales_rank <= 5
    GROUP BY ws_item_sk
), CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        CASE 
            WHEN d.cd_purchase_estimate > 5000 THEN 'High'
            WHEN d.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
), ShippingModes AS (
    SELECT 
        sm_ship_mode_sk,
        sm_type,
        SUM(ws_ext_ship_cost) AS total_ship_cost
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm_ship_mode_sk, sm_type
)
SELECT 
    cd.gender,
    cd.marital_status,
    cd.purchase_category,
    SUM(rs.total_sales_by_item) AS item_sales,
    sm.total_ship_cost,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM CustomerDemographics cd
LEFT JOIN RankedSales rs ON cd.c_customer_sk = rs.ws_item_sk -- Assuming a join key
JOIN ShippingModes sm ON sm.sm_ship_mode_sk IS NOT NULL
WHERE cd.cd_gender IS NOT NULL
GROUP BY cd.gender, cd.marital_status, cd.purchase_category, sm.total_ship_cost
HAVING SUM(rs.total_sales_by_item) > 1000
ORDER BY item_sales DESC;
