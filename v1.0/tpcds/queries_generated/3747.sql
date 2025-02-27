
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
SalesWithInventory AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_sold_date_sk,
        rs.total_sales,
        i.inv_quantity_on_hand,
        COALESCE(i.inv_quantity_on_hand, 0) AS adjusted_inventory
    FROM 
        RankedSales rs
    LEFT JOIN 
        inventory i ON rs.ws_sold_date_sk = i.inv_date_sk
    WHERE 
        i.inv_item_sk IN (SELECT DISTINCT cs.cs_item_sk FROM catalog_sales cs WHERE cs.cs_sold_date_sk = rs.ws_sold_date_sk)
),
FinalReport AS (
    SELECT 
        sw.web_site_sk,
        sw.ws_sold_date_sk,
        sw.total_sales,
        sw.inv_quantity_on_hand,
        sw.adjusted_inventory,
        CASE 
            WHEN sw.total_sales IS NULL THEN 'NO SALES'
            WHEN sw.total_sales > 1000 THEN 'HIGH SALES'
            ELSE 'LOW SALES' 
        END AS sales_category,
        CONCAT('Website SK: ', sw.web_site_sk, ', Date: ', sw.ws_sold_date_sk) AS report_description
    FROM 
        SalesWithInventory sw
)
SELECT 
    fr.web_site_sk,
    fr.ws_sold_date_sk,
    fr.total_sales,
    fr.inv_quantity_on_hand,
    fr.adjusted_inventory,
    fr.sales_category,
    fr.report_description
FROM 
    FinalReport fr
WHERE 
    fr.sales_category = 'HIGH SALES'
    OR fr.inv_quantity_on_hand IS NULL
ORDER BY 
    fr.total_sales DESC;
