
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
latest_sales AS (
    SELECT
        ws_item_sk,
        MAX(ws_sold_date_sk) AS max_date
    FROM 
        sales_summary
    GROUP BY 
        ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(ws.total_sales) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary ws ON c.c_customer_sk = ws.ws_item_sk
    JOIN 
        latest_sales ls ON ws.ws_item_sk = ls.ws_item_sk AND ws.ws_sold_date_sk = ls.max_date
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_income_band_sk
),
income_distribution AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(*) AS customer_count
    FROM 
        customer_info ci
    JOIN 
        household_demographics hd ON ci.cd_income_band_sk = hd.hd_income_band_sk
    JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
)
SELECT 
    ci.cd_gender,
    ib.ib_income_band_sk,
    COALESCE(id.customer_count, 0) AS customer_count,
    SUM(ci.total_sales) AS total_sales,
    AVG(ci.total_sales) AS avg_sales,
    MAX(ci.order_count) AS max_orders,
    MIN(ci.order_count) AS min_orders
FROM 
    customer_info ci
LEFT JOIN 
    income_distribution id ON ci.cd_income_band_sk = id.ib_income_band_sk
JOIN 
    income_band ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    ci.cd_gender, ib.ib_income_band_sk
ORDER BY 
    ci.cd_gender, ib.ib_income_band_sk;
