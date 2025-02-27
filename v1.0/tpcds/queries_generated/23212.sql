
WITH RECURSIVE inventory_analysis AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand,
        ROW_NUMBER() OVER (PARTITION BY inv_item_sk ORDER BY inv_date_sk) AS rn
    FROM inventory
    WHERE inv_quantity_on_hand IS NOT NULL
),
promoted_items AS (
    SELECT 
        p_item_sk,
        p_discount_active,
        p_start_date_sk,
        p_end_date_sk,
        p_cost * (CASE 
            WHEN p_discount_active = 'Y' THEN 0.9 
            ELSE 1 
        END) AS adjusted_cost
    FROM promotion 
    WHERE p_discount_active IS NOT NULL
),
customers_with_high_income AS (
    SELECT DISTINCT 
        c_customer_sk,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status,
        SUM(CASE 
            WHEN hd_income_band_sk IS NOT NULL THEN ib_upper_bound 
            ELSE 0 
        END) AS total_income
    FROM customer c 
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY c_customer_sk, cd_marital_status
),
sales_summary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        SUM(ss_sales_price) AS total_revenue,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM store_sales 
    GROUP BY ss_item_sk
),
web_sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_web,
        SUM(ws_sales_price) AS total_revenue_web
    FROM web_sales
    GROUP BY ws_item_sk
)
SELECT 
    inv.inv_item_sk,
    COALESCE(ss.total_sold, 0) AS total_store_sales,
    COALESCE(ws.total_sold_web, 0) AS total_web_sales,
    COALESCE(sa.total_income, 0) AS total_income_of_just_married,
    i.inv_quantity_on_hand,
    p.adjusted_cost,
    ROW_NUMBER() OVER (PARTITION BY inv.inv_item_sk ORDER BY inv.inv_date_sk DESC) AS latest_inventory_date
FROM inventory_analysis inv
LEFT JOIN sales_summary ss ON inv.inv_item_sk = ss.ss_item_sk
LEFT JOIN web_sales_summary ws ON inv.inv_item_sk = ws.ws_item_sk
LEFT JOIN customers_with_high_income sa ON sa.marital_status = 'Married' 
LEFT JOIN promoted_items p ON p.p_item_sk = inv.inv_item_sk
WHERE 
    (id_quantity_on_hand IS NOT NULL AND (COALESCE(ss.total_sold, 0) + COALESCE(ws.total_sold_web, 0)) > 0) 
    OR (p.adjusted_cost IS NOT NULL AND p.p_discount_active = 'Y')
ORDER BY total_inventory_date;
