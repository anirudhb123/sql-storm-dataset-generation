
WITH RECURSIVE inventory_summary AS (
    SELECT 
        i.inv_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory i
    GROUP BY 
        i.inv_item_sk
    HAVING 
        SUM(i.inv_quantity_on_hand) > 0
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
avg_sales AS (
    SELECT 
        AVG(total_sales) AS average_sales
    FROM 
        customer_sales
),
sales_details AS (
    SELECT 
        cs.c_customer_sk,
        ds.cd_gender,
        ds.purchase_category,
        ds.ib_income_band_sk,
        cs.total_sales,
        cs.order_count,
        cs.catalog_order_count,
        CASE 
            WHEN cs.total_sales > (SELECT average_sales FROM avg_sales) THEN 'Above Average'
            ELSE 'Below Average'
        END AS sales_performance
    FROM 
        customer_sales cs
    JOIN demographics ds ON cs.c_customer_sk = ds.cd_demo_sk
)
SELECT 
    sd.c_customer_sk,
    sd.cd_gender,
    sd.purchase_category,
    sd.ib_income_band_sk,
    sd.total_sales,
    sd.order_count,
    sd.catalog_order_count,
    sd.sales_performance,
    is.total_quantity
FROM 
    sales_details sd
LEFT JOIN inventory_summary is ON sd.c_customer_sk = is.inv_item_sk
WHERE 
    (sd.cd_gender = 'F' OR sd.cd_gender IS NULL)
    AND sd.total_sales > 0
ORDER BY 
    sd.total_sales DESC;
