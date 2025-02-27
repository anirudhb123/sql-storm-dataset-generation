
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
FilteredDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CASE 
            WHEN cd_purchase_estimate IS NULL THEN 0
            ELSE cd_purchase_estimate
        END AS adjusted_purchase_estimate,
        CAST(cd_gender AS VARCHAR(5)) || ' - ' || cd_marital_status AS gender_status
    FROM 
        customer_demographics
    WHERE 
        cd_dep_count >= (SELECT AVG(cd_dep_count) FROM customer_demographics)
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_paid,
        cd.gender_status
    FROM 
        RecursiveSales rs
    LEFT JOIN 
        FilteredDemographics cd ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = (
            SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = rs.ws_item_sk LIMIT 1))
    WHERE 
        rs.rn = 1
)
SELECT 
    ts.ws_item_sk,
    ts.total_quantity,
    ts.total_net_paid,
    COALESCE(ts.gender_status, 'Unknown') AS final_gender_status,
    CASE 
        WHEN ts.total_net_paid >= (SELECT AVG(total_net_paid) FROM RecursiveSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS net_paid_status
FROM 
    TopSales ts
WHERE 
    NOT EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk = ts.ws_item_sk AND ss.ss_net_paid < 0)
ORDER BY 
    ts.total_net_paid DESC
FETCH FIRST 10 ROWS ONLY;

DECLARE @item VARCHAR(16) = (SELECT i_item_id FROM item WHERE i_item_sk IN (SELECT ws_item_sk FROM web_sales ORDER BY ws_sales_price DESC LIMIT 1));
SELECT 
    i_item_id,
    i_item_desc, 
    COALESCE((SELECT MAX(ws_sales_price) FROM web_sales WHERE ws_item_sk = i_item_sk), 0) AS max_sales_price
FROM 
    item
WHERE 
    i_item_id = @item OR i_item_desc LIKE CONCAT('%Special%')
OPTION (RECOMPILE);
