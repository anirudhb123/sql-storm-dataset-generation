
WITH SalesData AS (
    SELECT 
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_paid) AS total_sales,
        SUM(cs.cs_ext_discount_amt) AS total_discount
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        cs.cs_sold_date_sk, cs.cs_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category
    FROM 
        item i
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    id.i_item_desc,
    id.i_brand,
    ROUND(sd.total_sales, 2) AS total_sales,
    ROUND(sd.total_discount, 2) AS total_discount,
    cd.ib_lower_bound,
    cd.ib_upper_bound
FROM 
    SalesData sd
JOIN 
    ItemDetails id ON sd.cs_item_sk = id.i_item_sk
JOIN 
    CustomerData cd ON sd.cs_item_sk IN (SELECT cs_item_sk FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = cd.c_customer_sk)
WHERE 
    ROUND(sd.total_sales, 2) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100
