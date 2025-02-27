
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT
        ws_item_sk,
        total_quantity,
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        (SELECT 
            ws_item_sk, 
            SUM(total_quantity) AS total_quantity, 
            SUM(total_sales) AS total_sales 
        FROM 
            RankedSales 
        WHERE 
            rank <= 5
        GROUP BY 
            ws_item_sk) AS aggregated_sales
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_income_band_sk
    FROM 
        customer_demographics
    WHERE 
        cd_income_band_sk IS NOT NULL
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ts.total_quantity,
    ts.total_sales
FROM 
    customer c
JOIN 
    TopSales ts ON c.c_customer_sk = ts.ws_item_sk -- Example join to associate customers with top-selling items
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND ts.sales_rank <= 10
ORDER BY 
    ts.total_sales DESC;
