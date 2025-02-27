
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COALESCE(CAST(c.c_birth_day AS CHAR(2)), '01') || '-' || 
        COALESCE(CAST(c.c_birth_month AS CHAR(2)), '01') || '-' || 
        COALESCE(CAST(c.c_birth_year AS CHAR(4)), '1970') AS birth_date
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sale_summary AS (
    SELECT 
        'WEB' AS sale_type,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales
    UNION ALL
    SELECT 
        'STORE' AS sale_type,
        SUM(ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_orders,
        COUNT(DISTINCT ss_customer_sk) AS unique_customers
    FROM 
        store_sales
),
sales_by_gender AS (
    SELECT 
        ci.cd_gender,
        SUM(ss.total_profit) AS total_profit,
        SUM(ss.total_orders) AS total_orders,
        SUM(ss.unique_customers) AS unique_customers
    FROM 
        customer_info ci
    JOIN 
        sale_summary ss ON (ci.c_customer_id IN (
            SELECT 
                ws_bill_customer_sk FROM web_sales
            UNION
            SELECT 
                ss_customer_sk FROM store_sales
        )
    )
    GROUP BY ci.cd_gender
)
SELECT 
    cb.cd_gender,
    cb.total_profit,
    cb.total_orders,
    cb.unique_customers,
    RANK() OVER (ORDER BY cb.total_profit DESC) AS profit_rank
FROM 
    sales_by_gender cb
ORDER BY 
    cb.total_profit DESC, cb.cd_gender;
