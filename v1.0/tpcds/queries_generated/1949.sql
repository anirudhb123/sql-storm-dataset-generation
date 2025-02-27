
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
SalesDeduplication AS (
    SELECT
        ws_item_sk,
        total_sales,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RankedSales
    WHERE 
        rn = 1
)

SELECT 
    ISNULL(c.c_first_name, 'Unknown') AS customer_first_name,
    ISNULL(c.c_last_name, 'Unknown') AS customer_last_name,
    i.i_item_id,
    i.i_item_desc,
    s.s_store_name,
    COALESCE(sales.sales_rank, 0) AS sales_rank,
    COALESCE(sales.total_sales, 0.00) AS total_sales
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT s_store_sk FROM store_sales WHERE ss_item_sk = ws.ws_item_sk ORDER BY ss_net_profit DESC LIMIT 1)
LEFT JOIN 
    SalesDeduplication sales ON i.i_item_sk = sales.ws_item_sk
WHERE 
    COALESCE(c.c_birth_year, -1) > 1980
    AND (c.c_current_hdemo_sk IN (SELECT hd_demo_sk FROM household_demographics WHERE hd_income_band_sk = 1)
         OR c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M'))
ORDER BY 
    total_sales DESC
LIMIT 100;
