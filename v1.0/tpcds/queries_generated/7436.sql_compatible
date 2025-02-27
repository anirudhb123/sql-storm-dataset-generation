
WITH SalesData AS (
    SELECT 
        cs.cs_customer_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count,
        AVG(cs.cs_sales_price) AS average_sales_price,
        MAX(cs.cs_sales_price) AS max_sales_price,
        MIN(cs.cs_sales_price) AS min_sales_price,
        sd.sd_year
    FROM 
        catalog_sales cs
    JOIN 
        date_dim sd ON cs.cs_sold_date_sk = sd.d_date_sk
    WHERE 
        sd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        cs.cs_customer_sk, cs.cs_item_sk, sd.sd_year
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        sd.cs_customer_sk,
        COUNT(DISTINCT sd.cs_item_sk) AS unique_items,
        SUM(sd.total_quantity) AS total_quantity_sold,
        SUM(sd.total_sales) AS total_sales_amount,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN sd.total_sales ELSE 0 END) AS male_sales,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN sd.total_sales ELSE 0 END) AS female_sales
    FROM 
        SalesData sd
    JOIN 
        CustomerDemographics cd ON sd.cs_customer_sk = cd.c_customer_sk
    GROUP BY 
        sd.cs_customer_sk
)
SELECT 
    css.cs_customer_sk,
    css.unique_items,
    css.total_quantity_sold,
    css.total_sales_amount,
    css.male_sales,
    css.female_sales,
    RANK() OVER (ORDER BY css.total_sales_amount DESC) AS sales_rank
FROM 
    SalesSummary css
WHERE 
    css.total_sales_amount > 10000
ORDER BY 
    sales_rank;
