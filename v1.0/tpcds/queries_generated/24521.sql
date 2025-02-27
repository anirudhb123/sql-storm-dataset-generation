
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn,
        COALESCE(cd.cd_dep_count, 0) AS dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
), 
customer_return_summary AS (
    SELECT 
        rc.c_customer_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(CASE WHEN sr.sr_return_quantity IS NULL THEN 0 ELSE sr.sr_return_quantity END) AS total_return_quantity
    FROM 
        ranked_customers rc
    LEFT JOIN 
        store_returns sr ON rc.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        rc.c_customer_sk
    HAVING 
        SUM(sr.sr_return_amt) > (SELECT AVG(sr_inner.sr_return_amt) FROM store_returns sr_inner WHERE sr_inner.sr_customer_sk IS NOT NULL)
), 
average_transaction_value AS (
    SELECT 
        c.c_customer_sk,
        AVG(ws.ws_net_paid) AS avg_transaction_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.total_returns,
        r.total_return_amount,
        a.avg_transaction_value,
        CASE 
            WHEN r.total_returns > 10 THEN 'Frequent Returner'
            WHEN r.total_returns IS NULL THEN 'No Returns'
            ELSE 'Occasional Returner'
        END AS returner_type
    FROM 
        ranked_customers c
    LEFT JOIN 
        customer_return_summary r ON c.c_customer_sk = r.c_customer_sk
    LEFT JOIN 
        average_transaction_value a ON c.c_customer_sk = a.c_customer_sk
)
SELECT 
    s.s_store_name,
    s.s_city,
    COUNT(DISTINCT sm.sm_ship_mode_id) AS ship_modes_count,
    AVG(NULLIF(s.ws_ext_sales_price, 0)) AS avg_sales,
    (SELECT SUM(ss_ext_sales_price) FROM store_sales WHERE ss_store_sk = s.s_store_sk) AS total_store_sales,
    MAX(CASE WHEN avg_transaction_value > 100 THEN 'High Value' ELSE 'Standard Value' END) AS value_category
FROM 
    store s
LEFT JOIN 
    web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
JOIN 
    summary su ON su.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
WHERE 
    s.s_state = 'CA' 
    AND (s.s_number_employees IS NULL OR s.s_number_employees > 20)
    AND EXISTS (SELECT 1 
                FROM customer c 
                WHERE c.c_current_addr_sk IS NULL 
                AND c.c_customer_sk = su.c_customer_sk)
GROUP BY 
    s.s_store_name, s.s_city
ORDER BY 
    s.s_city ASC,
    returner_type DESC
LIMIT 100 OFFSET 10;
