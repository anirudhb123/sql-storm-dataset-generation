
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TopCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.cd_gender,
        rc.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        rc.purchase_rank <= 10
    GROUP BY 
        rc.c_customer_id, rc.cd_gender, rc.cd_marital_status
)

SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales,
    tc.order_count,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales' 
        WHEN tc.total_sales > 1000 THEN 'High Roller' 
        ELSE 'Mainstream'
    END AS Customer_Type,
    COALESCE((
        SELECT 
            COUNT(*)
        FROM 
            store_sales ss
        WHERE 
            ss.ss_customer_sk = tc.c_customer_id
            AND ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    ), 0) AS store_sales_count
FROM 
    TopCustomers tc
WHERE 
    EXISTS (
        SELECT 1 
        FROM customer_address ca 
        WHERE ca.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_id = tc.c_customer_id)
          AND ca.ca_city = 'San Francisco'
    ) 
ORDER BY 
    total_sales DESC
LIMIT 50 
OFFSET 10;
