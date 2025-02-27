
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(dc.cd_gender, 'Unknown') AS gender,
        COALESCE(dc.cd_marital_status, 'Unknown') AS marital_status,
        COALESCE(dc.cd_education_status, 'Unknown') AS education_status,
        s.total_sales,
        s.order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics dc ON c.c_current_cdemo_sk = dc.cd_demo_sk
    JOIN 
        SalesCTE s ON c.c_customer_sk = s.ws_bill_customer_sk
    WHERE 
        s.rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.gender,
    tc.marital_status,
    tc.education_status,
    ROUND(tc.total_sales, 2) AS rounded_sales,
    CASE 
        WHEN tc.order_count > 10 THEN 'Frequent Buyer'
        WHEN tc.order_count BETWEEN 5 AND 10 THEN 'Occasional Buyer'
        ELSE 'Rare Buyer'
    END AS buyer_category,
    ROUND((SELECT AVG(total_sales) FROM SalesCTE) - tc.total_sales, 2) AS deviation_from_average
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_id)
WHERE 
    (tc.gender IS NOT NULL OR tc.marital_status IS NOT NULL) AND 
    (tc.education_status IS NOT NULL OR (tc.gender = 'M' AND tc.order_count < 3))
ORDER BY 
    tc.total_sales DESC, tc.c_last_name ASC;

WITH RECURSIVE DummyCTE AS (
    SELECT 1 AS num
    UNION ALL 
    SELECT num + 1 FROM DummyCTE WHERE num < 10
)
SELECT COUNT(*) FROM DummyCTE;
