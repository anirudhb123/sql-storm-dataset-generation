
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(wr.wr_return_quantity) AS total_web_returns,
        SUM(sr.sr_return_quantity) AS total_store_returns
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer_demographics cd
),
InventoryData AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(cs.cs_quantity) AS total_catalog_sales,
        SUM(ss.ss_quantity) AS total_store_sales
    FROM 
        web_sales ws
    FULL OUTER JOIN 
        catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    SUM(cs.total_web_returns + cs.total_store_returns) AS total_returns,
    SUM(sd.total_web_sales + sd.total_catalog_sales + sd.total_store_sales) AS total_sales,
    inv.total_inventory
FROM 
    CustomerReturns cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_sk = cd.cd_demo_sk
JOIN 
    SalesData sd ON cs.c_customer_sk = sd.ws_item_sk
JOIN 
    InventoryData inv ON sd.ws_item_sk = inv.inv_item_sk
WHERE 
    cd.cd_purchase_estimate > 100
GROUP BY 
    c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating, inv.total_inventory
ORDER BY 
    total_returns DESC, total_sales DESC
LIMIT 50;
