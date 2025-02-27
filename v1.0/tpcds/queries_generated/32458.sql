
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_net_profit,
        ss.total_orders
    FROM 
        customer cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        ss.rank <= 10
),
customer_with_address AS (
    SELECT 
        tc.c_customer_id,
        tc.c_first_name,
        tc.c_last_name,
        tc.total_net_profit,
        tc.total_orders,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        top_customers tc
    LEFT JOIN 
        customer_address ca ON ca.ca_address_sk = cs.c_current_addr_sk
),
date_range AS (
    SELECT 
        d.d_date AS report_date
    FROM 
        date_dim d
    WHERE 
        d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
final_summary AS (
    SELECT 
        cwa.*,
        dr.report_date,
        ROW_NUMBER() OVER (ORDER BY cwa.total_net_profit DESC, cwa.total_orders DESC) AS rank_in_year
    FROM 
        customer_with_address cwa,
        date_range dr
)
SELECT 
    cwa.c_customer_id,
    cwa.c_first_name,
    cwa.c_last_name,
    cwa.total_net_profit,
    cwa.total_orders,
    cwa.ca_city,
    cwa.ca_state,
    cwa.ca_country,
    f.report_date,
    CASE 
        WHEN f.rank_in_year <= 5 THEN 'Top 5'
        WHEN f.rank_in_year BETWEEN 6 AND 10 THEN 'Top 10'
        ELSE 'Other'
    END AS customer_rank_category,
    COUNT(*) OVER (PARTITION BY cwa.ca_city) AS city_customer_count
FROM 
    final_summary f
WHERE 
    f.total_net_profit IS NOT NULL
ORDER BY 
    f.total_net_profit DESC, 
    f.total_orders DESC;
