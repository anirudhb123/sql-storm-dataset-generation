
WITH demographic_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        SUM(cd_purchase_estimate) AS total_purchase_estimate,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dependency,
        SUM(CASE WHEN cd_credit_rating IS NULL THEN 1 ELSE 0 END) AS null_credit_count
    FROM 
        customer_demographics 
    JOIN 
        customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_education_status
), 
item_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    da.ca_city,
    ds.d_year,
    ds.d_month_seq,
    SUM(s.total_quantity_sold) AS total_qty_sold,
    AVG(ds.d_dow) AS avg_day_of_week,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    MAX(s.total_net_profit) AS max_profit,
    MAX(NULLIF(ds.d_holiday, 'Y')) AS non_holiday_count,
    STRING_AGG(DISTINCT CONCAT(demo.cd_gender, ': ', demo.total_purchase_estimate) ORDER BY demo.total_purchase_estimate DESC) AS gender_based_spending
FROM 
    date_dim ds
JOIN 
    store_sales ss ON ss.ss_sold_date_sk = ds.d_date_sk
JOIN 
    item_sales s ON s.ws_item_sk = ss.ss_item_sk
JOIN 
    warehouse w ON w.warehouse_sk = ss.ss_store_sk
RIGHT JOIN 
    demographic_summary demo ON demo.cd_demo_sk = ss.ss_customer_sk
WHERE 
    ds.d_year BETWEEN 2020 AND 2023
    AND (ds.d_weekend = 'Y' OR ds.d_holiday IS NULL)
GROUP BY 
    da.ca_city, ds.d_year, ds.d_month_seq
HAVING 
    COUNT(DISTINCT ss.ss_ticket_number) > 5
    AND MAX(s.total_net_profit) > 1000
ORDER BY 
    total_qty_sold DESC, ds.d_year, da.ca_city;
