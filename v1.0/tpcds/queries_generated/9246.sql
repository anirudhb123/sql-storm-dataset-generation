
WITH sales_summary AS (
    SELECT 
        w.warehouse_id,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_order_number) AS num_orders,
        AVG(ss_net_paid_inc_tax) AS avg_net_paid,
        SUM(ss_ext_discount_amt) AS total_discounts
    FROM 
        store_sales 
    INNER JOIN 
        warehouse w ON ss_store_sk = w.w_warehouse_sk
    WHERE 
        ss_sold_date_sk BETWEEN 2451545 AND 2451550  -- Example date range
    GROUP BY 
        w.warehouse_id
),
demographics_summary AS (
    SELECT 
        c_current_cdemo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS unique_customers,
        SUM(cd_purchase_estimate) AS total_purchase_estimates
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_current_cdemo_sk, cd_gender, cd_marital_status
)
SELECT 
    s.warehouse_id,
    ds.cd_gender,
    ds.cd_marital_status,
    ss.total_sales,
    ss.num_orders,
    ss.avg_net_paid,
    ss.total_discounts,
    ds.unique_customers,
    ds.total_purchase_estimates
FROM 
    sales_summary ss
JOIN 
    demographics_summary ds ON ds.c_current_cdemo_sk IN (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = 'SampleCity'))  -- Assume there is at least one relevant city in the database
JOIN 
    warehouse w ON ss.warehouse_id = w.w_warehouse_id
ORDER BY 
    total_sales DESC, unique_customers DESC
LIMIT 100;
