
WITH sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_sales_price) AS avg_sales_price
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2459504 AND 2459530
    GROUP BY 
        ss_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
store_details AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        w.w_warehouse_name
    FROM 
        store s
    JOIN 
        warehouse w ON s.s_store_sk = w.w_warehouse_sk
)
SELECT 
    si.s_store_name,
    sd.w_warehouse_name,
    SUM(ss.total_sales) AS store_total_sales,
    COUNT(ss.total_transactions) AS transaction_count,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    AVG(ss.avg_sales_price) AS average_sales_price,
    AVG(ci.cd_purchase_estimate) AS average_purchase_estimate
FROM 
    sales_summary ss
JOIN 
    store_details si ON ss.ss_store_sk = si.s_store_sk
JOIN 
    customer_info ci ON ci.d_year = 2023
GROUP BY 
    si.s_store_name, sd.w_warehouse_name
ORDER BY 
    store_total_sales DESC
LIMIT 10;
