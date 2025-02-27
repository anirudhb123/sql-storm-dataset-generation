
WITH SalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cs_ext_discount_amt) AS total_discount,
        AVG(cs_ext_tax) AS avg_tax
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name, i.i_current_price
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    sd.total_quantity,
    sd.total_sales,
    sd.total_discount,
    sd.avg_tax,
    id.i_product_name,
    id.i_current_price,
    id.total_orders
FROM 
    SalesData sd
JOIN 
    ItemDetails id ON sd.cs_item_sk = id.i_item_sk
JOIN 
    CustomerInfo ci ON sd.total_quantity > 100
ORDER BY 
    sd.total_sales DESC, ci.c_last_name ASC
LIMIT 50;
