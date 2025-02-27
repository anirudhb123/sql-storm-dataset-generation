
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_selling_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales
    FROM 
        sales_summary ss
    WHERE 
        ss.sales_rank <= 5
), 
return_data AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    i.i_item_id,
    i.i_product_name,
    COALESCE(ts.total_quantity, 0) AS sold_quantity,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    (COALESCE(ts.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales
FROM 
    customer_data ci
INNER JOIN 
    top_selling_items ts ON ci.c_customer_sk = ts.ws_item_sk
INNER JOIN 
    item i ON ts.ws_item_sk = i.i_item_sk
LEFT JOIN 
    return_data rd ON i.i_item_sk = rd.wr_item_sk
WHERE 
    ci.cd_income_band_sk IS NOT NULL 
ORDER BY 
    net_sales DESC;
