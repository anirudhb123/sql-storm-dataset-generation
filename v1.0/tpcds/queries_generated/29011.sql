
WITH customer_address_info AS (
    SELECT 
        ca.city AS city, 
        ca.state AS state, 
        COUNT(DISTINCT c.customer_id) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.city, ca.state
), demographics_info AS (
    SELECT 
        cd.gender AS gender,
        cd.marital_status AS marital_status,
        COUNT(c.c_customer_id) AS demographic_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.gender, cd.marital_status
), sales_data AS (
    SELECT 
        d.year AS sales_year, 
        SUM(ss.net_profit) AS total_net_profit
    FROM 
        store_sales ss
    JOIN 
        date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.year
), final_benchmark AS (
    SELECT 
        c.city,
        c.state,
        d.marital_status,
        d.gender,
        s.sales_year,
        s.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY c.city, c.state, d.marital_status, d.gender ORDER BY s.total_net_profit DESC) AS rank_within_group
    FROM 
        customer_address_info c
    JOIN 
        demographics_info d ON d.demographic_count > 0
    JOIN 
        sales_data s ON s.total_net_profit > 0
)
SELECT 
    city, 
    state, 
    marital_status, 
    gender, 
    sales_year, 
    total_net_profit 
FROM 
    final_benchmark
WHERE 
    rank_within_group <= 5
ORDER BY 
    city, state, marital_status, gender, total_net_profit DESC;
