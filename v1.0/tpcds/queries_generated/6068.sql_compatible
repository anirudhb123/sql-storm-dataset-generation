
WITH sales_data AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        cd.cd_gender,
        cd.cd_marital_status,
        wa.w_warehouse_name,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_sold_date_sk DESC) AS rn
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse wa ON ss.ss_store_sk = wa.w_warehouse_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE ss.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    AND ca.ca_state IN ('CA', 'NY', 'TX')
),
average_sales AS (
    SELECT
        sd.ca_state,
        sd.cd_gender,
        AVG(sd.ss_quantity) AS avg_quantity,
        AVG(sd.ss_sales_price) AS avg_sales_price,
        SUM(sd.ss_sales_price) AS total_sales
    FROM sales_data sd
    WHERE sd.rn = 1
    GROUP BY sd.ca_state, sd.cd_gender
)
SELECT
    as.ca_state,
    as.cd_gender,
    as.avg_quantity,
    as.avg_sales_price,
    as.total_sales,
    CASE 
        WHEN as.total_sales > 100000 THEN 'High Performer'
        WHEN as.total_sales BETWEEN 50000 AND 100000 THEN 'Moderate Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM average_sales as
ORDER BY as.total_sales DESC;
