
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_sales,
        i.i_item_desc,
        i.i_current_price,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        ranked_sales ri
    JOIN 
        item i ON ri.ws_item_sk = i.i_item_sk
    JOIN 
        customer c ON c.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ri.ws_item_sk)
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    WHERE 
        ri.rank <= 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_sales,
    ti.i_item_desc,
    ti.i_current_price,
    ti.cd_gender,
    ti.cd_marital_status,
    ti.ib_lower_bound,
    ti.ib_upper_bound
FROM 
    top_items ti
ORDER BY 
    ti.total_sales DESC;
