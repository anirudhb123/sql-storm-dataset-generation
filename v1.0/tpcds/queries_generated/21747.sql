
WITH RecursiveSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_ext_sales_price) AS total_sales
    FROM
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk, ss_item_sk
),
HighValueSales AS (
    SELECT 
        store_sk,
        item_sk,
        total_quantity,
        total_sales,
        ROW_NUMBER() OVER (PARTITION BY store_sk ORDER BY total_sales DESC) AS rank
    FROM 
        RecursiveSales
    WHERE 
        total_sales > 10000
),
TopSales AS (
    SELECT 
        h.store_sk,
        h.item_sk,
        h.total_quantity,
        h.total_sales,
        COALESCE(d.cd_gender, 'Unknown') AS gender,
        COALESCE(d.cd_marital_status, 'N') AS marital_status,
        d.cd_purchase_estimate,
        (SELECT COUNT(*) 
         FROM customer c
         WHERE c.c_current_cdemo_sk = d.cd_demo_sk AND c.c_birth_year < (EXTRACT(YEAR FROM CURRENT_DATE) - 18)) AS adult_count
    FROM 
        HighValueSales h
    LEFT JOIN 
        customer_demographics d ON h.store_sk = d.cd_demo_sk
    WHERE 
        h.rank <= 5
)
SELECT 
    t.ws_web_site_sk,
    w.w_warehouse_name,
    t.total_sales,
    COALESCE(SUM(r.cr_return_amount), 0) AS total_returns,
    SUM(-1 * t.total_sales * CASE WHEN c.cc_tax_percentage IS NULL THEN 0 ELSE c.cc_tax_percentage END / 100) AS total_tax,
    TRIM(COALESCE(STRING_AGG(DISTINCT CONCAT_WS(' ', c.c_first_name, c.c_last_name), ', '), 'No Purchases')) AS customers
FROM 
    TopSales t
LEFT JOIN 
    warehouse w ON t.store_sk = w.w_warehouse_sk
LEFT JOIN 
    catalog_returns r ON r.cr_item_sk = t.item_sk AND r.cr_order_number IN (SELECT ss_ticket_number FROM store_sales ss WHERE ss.ss_item_sk = t.item_sk)
LEFT JOIN 
    call_center c ON c.cc_call_center_sk = (SELECT cc_call_center_sk FROM store_sales s WHERE s.ss_item_sk = t.item_sk LIMIT 1)
GROUP BY 
    t.ws_web_site_sk, w.w_warehouse_name, t.total_sales
HAVING 
    SUM(r.cr_return_amount) < 0
ORDER BY 
    total_sales DESC, customers;
