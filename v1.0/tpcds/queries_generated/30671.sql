
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_quantity) + cte.total_quantity,
        SUM(cs_sales_price) + cte.total_sales
    FROM 
        catalog_sales cs
    JOIN SalesCTE cte ON cs.cs_item_sk = cte.ws_item_sk
    GROUP BY 
        cs_item_sk
),
DiscountedSales AS (
    SELECT 
        w.ws_item_sk,
        w.total_quantity,
        w.total_sales,
        CASE 
            WHEN w.total_sales > 1000 THEN w.total_sales * 0.1
            ELSE 0
        END AS discount_applied
    FROM 
        SalesCTE w
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ds.total_quantity,
        ds.total_sales,
        ds.discount_applied,
        ds.total_sales - ds.discount_applied AS net_sales
    FROM 
        CustomerInfo ci 
    JOIN 
        DiscountedSales ds ON ds.ws_item_sk IN (
            SELECT i_item_sk FROM item WHERE i_current_price < 50)
)
SELECT 
    fr.c_customer_sk,
    fr.c_first_name,
    fr.c_last_name,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.total_quantity,
    fr.total_sales,
    fr.discount_applied,
    fr.net_sales,
    ROW_NUMBER() OVER (PARTITION BY fr.cd_gender ORDER BY fr.net_sales DESC) AS rank
FROM 
    FinalReport fr
WHERE 
    fr.net_sales > 0
ORDER BY 
    fr.cd_gender, fr.net_sales DESC;
