
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        s.total_sales,
        s.total_orders,
        s.avg_profit
    FROM 
        RankedCustomers r
    JOIN 
        SalesSummary s ON r.c_customer_sk = s.customer_sk
    WHERE 
        r.rank <= 10
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_sales, 0) AS total_sales,
    COALESCE(tc.total_orders, 0) AS total_orders,
    COALESCE(tc.avg_profit, 0) AS avg_profit,
    CASE 
        WHEN tc.total_sales > 1000 THEN 'High Value Customer'
        WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_category
FROM 
    TopCustomers tc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state = 'CA'
ORDER BY 
    tc.total_sales DESC
;
