
WITH RECURSIVE address_hierarchy AS (
    SELECT 
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        1 AS level
    FROM 
        customer_address
    WHERE 
        ca_state IS NOT NULL
    
    UNION ALL
    
    SELECT 
        child.ca_address_sk,
        child.ca_street_name,
        child.ca_city,
        child.ca_state,
        parent.level + 1 AS level
    FROM 
        customer_address child
    INNER JOIN 
        address_hierarchy parent ON child.ca_city = parent.ca_city AND child.ca_state = parent.ca_state
    WHERE 
        child.ca_address_sk <> parent.ca_address_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_demo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS unique_orders
    FROM 
        customer_demographics cd
    LEFT JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
demographic_income AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE 
            WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', ib.ib_lower_bound, ' - $', ib.ib_upper_bound)
        END AS income_range
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    d.cd_gender,
    d.cd_marital_status,
    COALESCE(s.total_orders, 0) AS order_count,
    COALESCE(s.total_sales, 0) AS total_sales,
    i.income_range,
    a.ca_city,
    a.ca_state,
    ROW_NUMBER() OVER (PARTITION BY cu.c_customer_id ORDER BY s.total_sales DESC) AS sales_rank,
    CASE 
        WHEN s.total_sales > 1000 THEN 'High Value'
        WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value
FROM 
    customer cu
LEFT JOIN 
    customer_sales s ON cu.c_customer_sk = s.c_customer_sk
LEFT JOIN 
    customer_demo d ON cu.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    demographic_income i ON cu.c_current_hdemo_sk = i.hd_demo_sk
LEFT JOIN 
    address_hierarchy a ON cu.c_current_addr_sk = a.ca_address_sk
WHERE 
    d.unique_orders > 0
    AND (a.ca_state IS NULL OR a.ca_state = 'CA')
ORDER BY 
    total_sales DESC;
