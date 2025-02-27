
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower,
        COALESCE(ib.ib_upper_bound, 0) AS income_upper
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
DateSales AS (
    SELECT 
        dd.d_date,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM 
        date_dim dd
    LEFT JOIN 
        catalog_sales cs ON dd.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON dd.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        dd.d_date
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    cd.cd_marital_status,
    ds.total_catalog_sales,
    ds.total_web_sales,
    ds.total_store_sales,
    COALESCE(ds.total_catalog_sales, 0) + COALESCE(ds.total_web_sales, 0) + COALESCE(ds.total_store_sales, 0) AS total_sales,
    RANK() OVER (PARTITION BY ca.ca_city ORDER BY COALESCE(ds.total_catalog_sales, 0) + COALESCE(ds.total_web_sales, 0) + COALESCE(ds.total_store_sales, 0) DESC) AS city_sales_rank,
    CASE 
        WHEN ds.total_catalog_sales IS NULL THEN 'No Catalog Sales'
        ELSE 'Catalog Sales Available'
    END AS catalog_sales_status
FROM 
    customer c 
INNER JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    DateSales ds ON 1 = 1 
WHERE 
    cd.cd_gender = 'F' 
    AND ds.total_web_sales > (SELECT AVG(total_web_sales) FROM DateSales)
ORDER BY 
    total_sales DESC
LIMIT 100;
