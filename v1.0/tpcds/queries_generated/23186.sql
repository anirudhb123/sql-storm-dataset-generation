
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.web_site_sk, ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr.order_number) AS return_count,
        SUM(sr.return_amt) AS total_return_amt
    FROM store_returns sr
    GROUP BY sr_customer_sk
),
FilteredDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate IS NOT NULL AND
          (cd.cd_gender = 'M' OR cd.cd_gender IS NULL) AND
          cd.cd_marital_status <> 'D'
),
WarehouseInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS total_quantity_on_hand
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
WebSalesAndReturns AS (
    SELECT 
        w.ws_item_sk,
        SUM(w.ws_quantity) AS total_web_sales,
        COALESCE(SUM(r.wr_return_quantity), 0) AS total_web_returns
    FROM web_sales w
    LEFT JOIN web_returns r ON w.ws_item_sk = r.wr_item_sk
    GROUP BY w.ws_item_sk
)
SELECT 
    ca.ca_city,
    COALESCE(SUM(ws.total_sales), 0) AS web_total_sales,
    COALESCE(SUM(sr.return_count), 0) AS total_returns,
    SUM(wi.total_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cd.cd_demo_sk) AS total_demographics
FROM customer_address ca
LEFT JOIN RankedSales rs ON rs.web_site_sk = ca.ca_address_sk
LEFT JOIN CustomerReturns sr ON sr.sr_customer_sk = ca.ca_address_sk
LEFT JOIN WarehouseInventory wi ON wi.inv_item_sk = rs.web_site_sk 
LEFT JOIN FilteredDemographics cd ON cd.cd_demo_sk = ca.ca_address_sk
WHERE ca.ca_city IS NOT NULL
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT rs.sales_rank) > 1
ORDER BY 1;
