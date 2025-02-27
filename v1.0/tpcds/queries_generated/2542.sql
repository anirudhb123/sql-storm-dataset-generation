
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        AVG(ws_net_paid_inc_tax) AS avg_order_value,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND 
                                 (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
customer_address_info AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        c.customer_id,
        c.total_orders,
        c.total_sales,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender
    FROM 
        sales_summary c
    JOIN 
        customer_address_info ca ON c.customer_id = ca.c_customer_sk
    WHERE 
        c.total_sales > (SELECT AVG(total_sales) FROM sales_summary) * 1.5
)
SELECT 
    hvc.customer_id,
    hvc.total_orders,
    hvc.total_sales,
    hvc.ca_city,
    hvc.ca_state,
    hvc.cd_gender,
    CASE 
        WHEN hvc.cd_gender = 'M' THEN 'Male' 
        WHEN hvc.cd_gender = 'F' THEN 'Female' 
        ELSE 'Other' 
    END AS gender_desc
FROM 
    high_value_customers hvc
ORDER BY 
    hvc.total_sales DESC
LIMIT 10;

```
