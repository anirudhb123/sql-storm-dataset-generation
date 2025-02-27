
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        SUM(ws_quantity) AS total_sales, 
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, 
        ws_order_number
),
Customer_Info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.web_site_sk) AS web_purchase_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        cd.cd_credit_rating
),
Top_Customers AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY web_purchase_count DESC) AS customer_rank
    FROM 
        Customer_Info c
)
SELECT 
    sc.ws_item_sk, 
    sc.ws_order_number, 
    sc.total_sales, 
    tc.c_first_name, 
    tc.c_last_name, 
    tc.cd_gender, 
    tc.cd_marital_status, 
    tc.web_purchase_count
FROM 
    Sales_CTE sc
JOIN 
    Top_Customers tc ON tc.customer_rank <= 10
WHERE 
    sc.total_sales > (SELECT AVG(total_sales) FROM Sales_CTE)
ORDER BY 
    sc.total_sales DESC
LIMIT 100;
