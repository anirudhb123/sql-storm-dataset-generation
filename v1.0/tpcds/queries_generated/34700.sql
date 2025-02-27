
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_customer_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_customer_sk, ws_item_sk
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender IS NOT NULL
        AND ca.ca_city IS NOT NULL
),
Sales_Summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(s.total_sales) AS total_sales_value,
        COUNT(DISTINCT s.ws_item_sk) AS item_count,
        AVG(s.total_sales) AS avg_sales_per_item
    FROM 
        Sales_CTE s
    JOIN 
        Customer_Info c ON s.ws_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    COALESCE(s.total_sales_value, 0) AS total_sales_value,
    COALESCE(s.item_count, 0) AS item_count,
    COALESCE(s.avg_sales_per_item, 0.00) AS avg_sales_per_item,
    ci.ca_city AS customer_city
FROM 
    Sales_Summary s
FULL OUTER JOIN 
    Customer_Info ci ON s.c_customer_sk = ci.c_customer_sk
WHERE 
    (s.total_sales_value > 1000 OR ci.ca_city IS NOT NULL)
    AND (s.avg_sales_per_item IS NOT NULL OR s.item_count IS NULL)
ORDER BY 
    s.total_sales_value DESC NULLS LAST
LIMIT 100;
