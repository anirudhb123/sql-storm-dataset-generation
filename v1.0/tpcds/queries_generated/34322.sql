
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_totals AS (
    SELECT 
        c_current_cdemo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer 
    LEFT JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        c_current_cdemo_sk
),
detailed_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        ct.customer_count,
        ct.total_purchase_estimate,
        CASE 
            WHEN ct.customer_count IS NULL THEN 'Unregistered'
            ELSE 'Registered'
        END AS customer_status
    FROM 
        sales_data sd
    LEFT JOIN 
        customer_totals ct ON sd.ws_item_sk = ct.c_current_cdemo_sk
),
daily_sales AS (
    SELECT 
        dd.d_date,
        SUM(ds.total_sales) AS daily_total_sales,
        COUNT(DISTINCT ds.ws_item_sk) AS unique_items_sold
    FROM 
        detailed_sales ds
    JOIN 
        date_dim dd ON ds.ws_item_sk IN (SELECT distinct ws_item_sk FROM web_sales WHERE ws_sold_date_sk = dd.d_date_sk)
    GROUP BY 
        dd.d_date
)
SELECT 
    d.d_date,
    ds.daily_total_sales,
    ds.unique_items_sold,
    (SELECT AVG(daily_total_sales) FROM daily_sales) AS avg_sales,
    (SELECT SUM(unique_items_sold) FROM daily_sales) AS total_unique_items_sold,
    (SELECT COUNT(*) FROM customer WHERE c_birth_country IS NULL) AS null_country_count,
    CASE 
        WHEN ds.daily_total_sales > (SELECT AVG(daily_total_sales) FROM daily_sales)
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    daily_sales ds
JOIN 
    date_dim d ON ds.d_date = d.d_date
WHERE 
    d.d_year = 2023 
    AND d.d_moy IN (1, 2, 3) -- only first quarter
ORDER BY 
    d.d_date DESC;
