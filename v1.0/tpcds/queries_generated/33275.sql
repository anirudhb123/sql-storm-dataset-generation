
WITH RECURSIVE sales_data AS (
    SELECT 
        s_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count,
        SUM(ss_quantity) AS total_quantity
    FROM 
        store_sales
    WHERE 
         ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s_store_sk

    UNION ALL

    SELECT 
        s.s_store_sk,
        SUM(ss.ss_sales_price) + sd.total_sales AS total_sales,
        COUNT(ss.ss_ticket_number) + sd.transaction_count AS transaction_count,
        SUM(ss.ss_quantity) + sd.total_quantity AS total_quantity
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    JOIN 
        sales_data sd ON sd.s_store_sk = s.s_store_sk
    WHERE 
        ss_ss_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_store_sk, sd.total_sales, sd.transaction_count, sd.total_quantity
),

customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),

filtered_sales AS (
    SELECT 
        sd.s_store_sk,
        sd.total_sales,
        sd.transaction_count,
        CASE 
            WHEN cd.rank <= 10 THEN 'Top Customers'
            ELSE 'Other Customers'
        END AS customer_segment
    FROM 
        sales_data sd
    JOIN 
        customer_details cd ON cd.c_customer_sk = sd.s_store_sk
)

SELECT 
    f.s_store_sk,
    f.total_sales,
    f.transaction_count,
    f.customer_segment,
    AVG(f.total_sales) OVER (PARTITION BY f.customer_segment) AS avg_sales_per_segment
FROM 
    filtered_sales f
WHERE 
    f.transaction_count > 0
ORDER BY 
    f.total_sales DESC;
