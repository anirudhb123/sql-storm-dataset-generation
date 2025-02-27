
WITH RECURSIVE address_hierarchy AS (
    SELECT 
        ca_address_sk, 
        ca_address_id, 
        ca_street_name, 
        ca_city, 
        ca_country, 
        1 AS level
    FROM 
        customer_address 
    WHERE 
        ca_country IS NOT NULL
    UNION ALL
    SELECT 
        ca.ca_address_sk, 
        ca.ca_address_id, 
        ca.ca_street_name, 
        ca.ca_city,
        ca.ca_country,
        ah.level + 1
    FROM 
        customer_address ca
    JOIN 
        address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE 
        ca.ca_city = ah.ca_city AND 
        ca.ca_country = ah.ca_country
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_paid) AS avg_payment,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        SUM(coalesce(ss_net_paid, 0)) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        total_spent > (SELECT AVG(total_spent) FROM (SELECT SUM(coalesce(ss_net_paid, 0)) AS total_spent FROM customer c LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk GROUP BY c_customer_sk) AS avg_totals)
),
final_report AS (
    SELECT 
        ah.ca_city,
        ah.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(s.total_sales) AS total_sales_value,
        SUM(hvc.total_spent) AS high_value_customer_contribution
    FROM 
        address_hierarchy ah
    INNER JOIN 
        customer c ON c.c_current_addr_sk = ah.ca_address_sk
    LEFT JOIN 
        sales_summary s ON s.ws_item_sk = c.c_customer_sk
    LEFT JOIN 
        high_value_customers hvc ON hvc.c_customer_sk = c.c_customer_sk
    GROUP BY 
        ah.ca_city, ah.ca_country
)
SELECT 
    ca_city, 
    ca_country, 
    unique_customers, 
    total_sales_value, 
    high_value_customer_contribution,
    CASE 
        WHEN unique_customers > 0 THEN total_sales_value / unique_customers 
        ELSE NULL 
    END AS avg_sales_per_customer
FROM 
    final_report
WHERE 
    total_sales_value > 50000
ORDER BY 
    total_sales_value DESC;
