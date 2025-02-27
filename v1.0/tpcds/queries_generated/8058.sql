
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2024)
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_sales,
        rs.order_count
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.rank <= 10
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_sales,
    tsi.order_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    hd.hd_income_band_sk,
    hd.hd_buy_potential
FROM 
    TopSellingItems tsi
LEFT JOIN 
    customer c ON c.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = tsi.ws_item_sk LIMIT 1)
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
ORDER BY 
    tsi.total_sales DESC;
