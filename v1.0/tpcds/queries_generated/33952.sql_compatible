
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        sales.total_sales,
        DENSE_RANK() OVER (ORDER BY sales.total_sales DESC) AS sales_rank
    FROM 
        SalesData sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales_rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
FinalReport AS (
    SELECT 
        num.daily_sales,
        num.date,
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ti.i_product_name,
        ti.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.income_band
    FROM 
        (SELECT 
            d.d_date AS date,
            SUM(ws.ws_net_paid) AS daily_sales
        FROM 
            date_dim d
        JOIN 
            web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
        GROUP BY 
            d.d_date) num
    JOIN 
        customer ci ON ci.c_customer_sk = (
            SELECT 
                ws_bill_customer_sk 
            FROM 
                web_sales 
            WHERE 
                ws_sold_date_sk = d.d_date_sk 
            LIMIT 1
        )
    JOIN 
        TopItems ti ON ti.i_item_sk = (
            SELECT 
                ws_item_sk 
            FROM 
                web_sales 
            WHERE 
                ws_sold_date_sk = d.d_date_sk 
            LIMIT 1
        )
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk = ci.c_current_cdemo_sk
)
SELECT 
    COALESCE(f.date, 'Unknown') AS report_date,
    COALESCE(f.daily_sales, 0) AS total_sales,
    COALESCE(f.c_first_name, 'N/A') AS first_name,
    COALESCE(f.c_last_name, 'N/A') AS last_name,
    COALESCE(f.c_email_address, 'N/A') AS email,
    COALESCE(f.i_product_name, 'N/A') AS product_name,
    COALESCE(f.total_sales, 0) AS item_sales,
    f.cd_gender,
    f.cd_marital_status,
    CASE 
        WHEN f.income_band IS NULL THEN 'Income Band Not Available' 
        ELSE f.income_band 
    END AS income_band
FROM 
    FinalReport f
ORDER BY 
    f.date DESC;
