
WITH RECURSIVE customer_activity AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
expanded_addresses AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city || ', ' || ca.ca_state AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_address_sk) as addr_rank
    FROM 
        customer_address ca
    WHERE 
        ca.ca_city IS NOT NULL
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        d.d_date,
        d.d_month_seq,
        d.d_year,
        ca.full_address,
        ca.addr_rank,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim d ON d.d_date_sk = c.c_first_sales_date_sk
    LEFT JOIN 
        expanded_addresses ca ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    ci.c_customer_sk,
    ci.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ca.total_orders, 0) AS orders_count,
    COALESCE(ca.total_profit, 0.00) AS profit,
    CASE 
        WHEN ci.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single' 
    END AS marital_status,
    (SELECT COUNT(*) 
     FROM store_sales ss 
     WHERE ss.ss_customer_sk = ci.c_customer_sk 
       AND ss.ss_sold_date_sk BETWEEN 
           (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) AND 
           (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    ) AS store_purchases,
    (SELECT 
        AVG(ws.ws_net_paid) 
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_bill_customer_sk = ci.c_customer_sk 
        AND ws.ws_sold_date_sk <= CURRENT_DATE
    ) AS avg_web_spend
FROM 
    customer_info ci
LEFT JOIN 
    customer_activity ca ON ci.c_customer_sk = ca.c_customer_sk
WHERE 
    (ci.addr_rank = 1 OR ci.addr_rank IS NULL)
    AND (ci.cd_gender = 'F' OR ci.cd_gender IS NULL)
ORDER BY 
    profit DESC, ci.c_first_name ASC
LIMIT 100
OFFSET 10;
