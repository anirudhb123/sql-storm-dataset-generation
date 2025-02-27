
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2022-12-31')
    GROUP BY 
        ws_item_sk
),

TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales 
    FROM 
        item i
    JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.sales_rank <= 10
),

CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY c.c_first_name) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)

SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    SUM(ti.total_quantity) AS total_quantity_sold,
    SUM(tc.cust_count) AS total_customers,
    COUNT(DISTINCT cd.c_customer_id) AS unique_customer_count,
    MAX(cd.cd_gender) AS predominant_gender
FROM 
    TopItems ti
LEFT JOIN 
    (
        SELECT 
            ws_item_sk,
            COUNT(DISTINCT ws_bill_customer_sk) AS cust_count
        FROM 
            web_sales 
        GROUP BY 
            ws_item_sk
    ) AS tc ON ti.ws_item_sk = tc.ws_item_sk
LEFT JOIN 
    CustomerDetails cd ON cd.customer_rank <= 10
GROUP BY 
    ti.i_item_id, ti.i_item_desc
ORDER BY 
    total_quantity_sold DESC
LIMIT 20;
