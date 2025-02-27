
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_quantity) > 0
    UNION ALL
    SELECT 
        s.ws_sold_date_sk, 
        s.ws_item_sk, 
        s.total_quantity + c.cs_quantity AS total_quantity, 
        s.total_sales + c.cs_net_paid_inc_tax AS total_sales
    FROM 
        SalesCTE s
    JOIN 
        catalog_sales c ON s.ws_item_sk = c.cs_item_sk AND s.ws_sold_date_sk = c.cs_sold_date_sk
),
FilteredSales AS (
    SELECT 
        s.ws_item_sk, 
        SUM(s.total_sales) AS aggregate_sales
    FROM 
        SalesCTE s
    WHERE 
        s.total_sales IS NOT NULL
    GROUP BY 
        s.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cond.ca_state,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            ELSE CAST(cd.cd_purchase_estimate AS VARCHAR)
        END AS purchase_estimate_category
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address cond ON c.c_current_addr_sk = cond.ca_address_sk
)
SELECT 
    f.ws_item_sk, 
    f.aggregate_sales, 
    cd.cd_gender, 
    cd.purchase_estimate_category
FROM 
    FilteredSales f
LEFT JOIN 
    CustomerDemographics cd ON f.ws_item_sk = cd.cd_demo_sk
WHERE 
    f.aggregate_sales > 10000 
    AND cd.cd_marital_status = 'M'
    AND cd.ca_state IS NOT NULL
ORDER BY 
    f.aggregate_sales DESC
LIMIT 10;
