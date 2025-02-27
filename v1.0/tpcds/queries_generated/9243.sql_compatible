
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20230101 AND 20230331
    GROUP BY 
        ws_bill_customer_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
demographic_sales AS (
    SELECT 
        ci.customer_value_segment,
        ci.cd_gender,
        ci.cd_marital_status,
        SUM(sd.total_sales) AS segment_sales,
        COUNT(DISTINCT sd.customer_id) AS customer_count
    FROM 
        sales_data sd
    JOIN 
        customer_info ci ON sd.customer_id = ci.c_customer_id
    GROUP BY 
        ci.customer_value_segment, ci.cd_gender, ci.cd_marital_status
)
SELECT 
    ds.customer_value_segment,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.segment_sales,
    ds.customer_count,
    RANK() OVER (PARTITION BY ds.cd_gender ORDER BY ds.segment_sales DESC) AS sales_rank
FROM 
    demographic_sales ds
ORDER BY 
    ds.customer_value_segment, ds.cd_gender, ds.segment_sales DESC;
