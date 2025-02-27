
WITH RECURSIVE sales_totals AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE(i.i_current_price, 0) AS current_price,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential
    FROM item i
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = (
        SELECT c.c_current_cdemo_sk 
        FROM customer c 
        WHERE c.c_customer_sk IN (
            SELECT DISTINCT ws_bill_customer_sk 
            FROM web_sales 
            WHERE ws_item_sk = i.i_item_sk
        )
        LIMIT 1
    )
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
),
filtered_sales AS (
    SELECT 
        st.ws_item_sk,
        st.total_quantity,
        st.total_sales,
        id.i_product_name,
        id.current_price,
        id.cd_gender,
        id.cd_marital_status,
        id.buy_potential
    FROM sales_totals st
    JOIN item_details id ON st.ws_item_sk = id.i_item_sk
    WHERE st.rn = 1
    AND st.total_sales > 1000
)
SELECT 
    fs.i_product_name,
    fs.current_price,
    fs.total_quantity,
    fs.total_sales,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.buy_potential,
    COALESCE(CAST(wr_returned_date_sk AS DATE), '1970-01-01') AS return_date,
    COUNT(wr.returned_date_sk) AS return_count
FROM filtered_sales fs
LEFT JOIN web_returns wr ON fs.ws_item_sk = wr.wr_item_sk
GROUP BY 
    fs.i_product_name, 
    fs.current_price, 
    fs.total_quantity, 
    fs.total_sales, 
    fs.cd_gender, 
    fs.cd_marital_status, 
    fs.buy_potential, 
    wr.returned_date_sk
ORDER BY fs.total_sales DESC
LIMIT 50;
