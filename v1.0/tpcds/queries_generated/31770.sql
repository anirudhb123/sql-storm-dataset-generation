
WITH RECURSIVE cte_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || c_first_name
            WHEN cd_gender = 'F' THEN 'Ms. ' || c_first_name
            ELSE c_first_name 
        END AS full_name,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        ca_state,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        cte_sales sal ON c.c_customer_sk = sal.ws_bill_customer_sk
    WHERE 
        sal.rnk <= 10
),
sales_summary AS (
    SELECT 
        st.store_name,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        AVG(ss_list_price) AS avg_list_price
    FROM 
        store_sales
    JOIN 
        store st ON st.s_store_sk = ss_store_sk
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        st.store_name
),
final_report AS (
    SELECT 
        tc.c_customer_sk,
        tc.full_name,
        tc.cd_marital_status,
        ss.store_name,
        ss.total_sales,
        ss.total_discount,
        ss.total_transactions,
        CASE 
            WHEN ss.total_sales IS NULL THEN 'No Sales'
            ELSE TO_CHAR(ss.total_sales, 'FM$999,999.00')
        END AS formatted_sales
    FROM 
        top_customers tc
    LEFT JOIN 
        sales_summary ss ON tc.customer_rank = ss.total_transactions
)
SELECT 
    *
FROM 
    final_report
WHERE 
    cd_marital_status = 'M'
ORDER BY 
    total_sales DESC NULLS LAST;
