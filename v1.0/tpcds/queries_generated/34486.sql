
WITH RECURSIVE top_customers AS (
    SELECT 
        cd_demo_sk,
        SUM(ws_net_paid) AS total_spent
    FROM 
        web_sales
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
customer_addresses AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity
    FROM 
        customer c
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, ca.ca_city, ca.ca_state, ca.ca_country
),
sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss_net_paid) AS total_sales,
        AVG(ss_net_profit) AS avg_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    JOIN 
        store s ON ss_store_sk = s.s_store_sk
    WHERE 
        ss_sold_date_sk >= (SELECT 
                                MIN(d_date_sk) 
                            FROM 
                                date_dim 
                            WHERE 
                                d_year = 2023)
    GROUP BY 
        s.s_store_id
),
returns_summary AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    ca.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    cs.total_sales,
    COALESCE(rs.total_returns, 0) AS total_returns,
    cs.total_sales - COALESCE(rs.total_returns, 0) AS net_sales,
    (cs.total_sales / NULLIF(cs.total_transactions, 0)) AS avg_sales_per_transaction
FROM 
    customer_addresses ca
JOIN 
    sales_summary cs ON ca.c_customer_id = cs.s_store_id
LEFT JOIN 
    returns_summary rs ON cs.s_store_id = rs.sr_store_sk
WHERE 
    ca.total_quantity > (SELECT AVG(total_quantity) FROM customer_addresses)
ORDER BY 
    net_sales DESC;
