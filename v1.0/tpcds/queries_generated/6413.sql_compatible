
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        r.ws_sold_date_sk,
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_category,
        i.i_brand
    FROM 
        item i
)
SELECT 
    d.d_date,
    t.total_quantity,
    t.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    id.i_item_desc,
    id.i_category,
    id.i_brand
FROM 
    TopSales t
JOIN 
    date_dim d ON t.ws_sold_date_sk = d.d_date_sk
JOIN 
    web_sales ws ON t.ws_item_sk = ws.ws_item_sk AND t.ws_sold_date_sk = ws.ws_sold_date_sk
JOIN 
    CustomerDemographics cd ON ws.ws_ship_customer_sk = cd.c_customer_sk
JOIN 
    ItemDetails id ON t.ws_item_sk = id.i_item_sk
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date, t.total_sales DESC;
