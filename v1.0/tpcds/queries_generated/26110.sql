
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS upper_city_name
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        a.full_address,
        a.street_name_length,
        a.upper_city_name
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        processed_addresses a ON c.c_current_addr_sk = a.ca_address_sk
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN cs.sold_date_sk IS NOT NULL THEN 'Catalog Sales'
            WHEN ws.sold_date_sk IS NOT NULL THEN 'Web Sales'
            ELSE 'Store Sales'
        END AS sale_type,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(COALESCE(cs.cs_net_profit,0) + COALESCE(ws.ws_net_profit,0) + COALESCE(ss.ss_net_profit,0)) AS total_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        catalog_sales cs ON ci.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON ci.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        sale_type, ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    sale_type,
    c_customer_sk,
    c_first_name,
    c_last_name,
    total_profit,
    RANK() OVER (PARTITION BY sale_type ORDER BY total_profit DESC) AS profit_rank
FROM 
    sales_summary
WHERE 
    total_profit > 0
ORDER BY 
    sale_type, profit_rank;
