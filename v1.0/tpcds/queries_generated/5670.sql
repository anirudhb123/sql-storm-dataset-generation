
WITH sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers,
        SUM(ss_ext_discount_amt) AS total_discount
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
),
customer_demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
    WHERE 
        cd_credit_rating IN ('High', 'Medium')
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        SUM(ss.net_profit) AS total_profit
    FROM 
        customer c 
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_email_address
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ss.ss_net_profit) AS total_profit_by_warehouse
    FROM 
        warehouse w
    JOIN 
        store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT 
    ss.ss_store_sk,
    ss.total_quantity,
    ss.total_net_profit,
    ss.unique_customers,
    ss.total_discount,
    cd.cd_gender,
    cd.cd_marital_status,
    customer_info.c_first_name,
    customer_info.c_last_name,
    customer_info.total_profit AS customer_profit,
    warehouse_info.w_warehouse_name,
    warehouse_info.total_profit_by_warehouse
FROM 
    sales_summary ss
JOIN 
    customer_demographics cd ON ss.unique_customers = cd.cd_demo_sk
JOIN 
    customer_info ON customer_info.total_profit > 1000
JOIN 
    warehouse_info ON ss.ss_store_sk = warehouse_info.w_warehouse_sk
ORDER BY 
    ss.total_net_profit DESC, 
    customer_info.total_profit DESC;
