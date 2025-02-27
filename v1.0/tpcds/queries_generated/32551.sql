
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
Top_Customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.total_sales
    FROM 
        customer c
    JOIN 
        Sales_CTE s ON c.c_customer_sk = s.customer_id
    WHERE 
        s.sales_rank <= 10
),
Customer_Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        Top_Customers tc ON cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_id = tc.c_customer_id LIMIT 1)
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
Sales_Analysis AS (
    SELECT 
        t.cd_gender,
        t.cd_marital_status,
        t.customer_count,
        t.avg_purchase_estimate,
        CASE 
            WHEN t.avg_purchase_estimate > 1000 THEN 'High'
            WHEN t.avg_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM 
        Customer_Demographics t
),
Sales_Summary AS (
    SELECT 
        ca.ca_state,
        SUM(sa.customer_count) AS demographic_count,
        AVG(sa.avg_purchase_estimate) AS avg_purchase_per_category,
        ARRAY_AGG(DISTINCT sa.purchase_category) AS purchase_categories
    FROM 
        Sales_Analysis sa
    LEFT JOIN 
        customer c ON c.c_customer_id IN (SELECT c_customer_id FROM Top_Customers)
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    s.ca_state,
    s.demographic_count,
    s.avg_purchase_per_category,
    CASE 
        WHEN s.avg_purchase_per_category IS NULL THEN 'No Data'
        ELSE s.purchase_categories[1]
    END AS predominant_purchase_category
FROM 
    Sales_Summary s
ORDER BY 
    s.demographic_count DESC;
