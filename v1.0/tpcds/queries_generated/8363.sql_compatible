
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        SUM(ws_ext_tax) AS total_tax
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_gender,
        cd.cd_demo_sk,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
SalesSummary AS (
    SELECT 
        sd.ws_sold_date_sk,
        cd.c_customer_sk,
        cd.cd_demo_sk,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.total_discount) AS total_discount,
        SUM(sd.total_tax) AS total_tax
    FROM 
        SalesData sd
    JOIN 
        CustomerDetails cd ON sd.ws_item_sk IN (SELECT i_item_sk FROM item WHERE i_brand_id = 1)
    GROUP BY 
        sd.ws_sold_date_sk, cd.c_customer_sk, cd.cd_demo_sk
)

SELECT 
    ds.d_date,
    ss.cd_demo_sk,
    ss.total_quantity,
    ss.total_sales,
    ss.total_discount,
    ss.total_tax,
    CASE 
        WHEN ss.total_sales > 1000 THEN 'High'
        WHEN ss.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    SalesSummary ss
JOIN 
    date_dim ds ON ss.ws_sold_date_sk = ds.d_date_sk
WHERE 
    ds.d_year = 2023
ORDER BY 
    ds.d_date, ss.total_sales DESC;
