
WITH RECURSIVE date_range AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_date >= DATE '2022-01-01'
    UNION ALL
    SELECT d_date_sk + 1, DATE '2022-01-01' + (d_date_sk + 1)
    FROM date_range
    WHERE d_date_sk < (SELECT MAX(d_date_sk) FROM date_dim)
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
), sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM web_sales ws
    JOIN date_range dr ON ws.ws_sold_date_sk = dr.d_date_sk
    GROUP BY ws.ws_item_sk
), detailed_sales AS (
    SELECT 
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_discount_amt,
        COALESCE(ws.total_quantity, 0) AS web_total_quantity,
        COALESCE(ws.total_sales, 0) AS web_total_sales,
        COALESCE(ws.avg_sales_price, 0) AS web_avg_sales_price
    FROM catalog_sales cs
    LEFT JOIN sales_summary ws ON cs.cs_item_sk = ws.ws_item_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ds.cs_order_number,
    ds.cs_sales_price,
    ds.web_total_quantity,
    ds.web_total_sales,
    ds.web_avg_sales_price,
    'Income Sk: ' || ci.income_band_sk AS band_info,
    CASE 
        WHEN ci.cd_marital_status IS NULL THEN 'No Marital Status'
        ELSE ci.cd_marital_status
    END AS marital_status,
    CASE 
        WHEN ds.cs_discount_amt IS NULL THEN 'No Discounts'
        WHEN ds.cs_discount_amt > 0 THEN 'Discount Given'
        ELSE 'Full Price'
    END AS discount_info,
    CASE 
        WHEN ds.web_avg_sales_price > 0 THEN 'Sales Avg: ' || ROUND(ds.web_avg_sales_price, 2)
        ELSE 'No Sales'
    END AS sales_average
FROM customer_info ci
JOIN detailed_sales ds ON ci.c_customer_sk = ds.cs_item_sk
WHERE (ci.cd_dep_count > 2 OR ci.cd_purchase_estimate > 1000)
ORDER BY ci.c_last_name, ci.c_first_name, ds.cs_order_number DESC
FETCH FIRST 100 ROWS ONLY;
