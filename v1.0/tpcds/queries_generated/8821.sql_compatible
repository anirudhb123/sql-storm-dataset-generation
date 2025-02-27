
WITH sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discounts,
        COUNT(ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                 (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        address.ca_city,
        address.ca_state,
        address.ca_zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address address ON c.c_current_addr_sk = address.ca_address_sk
),
top_customers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(ss.total_sales) AS total_spent
    FROM 
        customer_info ci
    JOIN 
        store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    ss.total_sales,
    ss.total_discounts,
    ss.total_transactions,
    (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk) AS web_order_count,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = tc.c_customer_sk) AS catalog_order_count,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = tc.c_customer_sk) AS total_returns
FROM 
    top_customers tc
JOIN 
    sales_summary ss ON tc.c_customer_sk = ss.ss_store_sk;
