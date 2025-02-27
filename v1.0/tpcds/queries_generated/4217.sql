
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) as total_sales,
        COUNT(ws.ws_order_number) as order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_sales_price) DESC) as sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
), 
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE 
        cs.total_sales > 5000
)

SELECT 
    hvc.c_customer_id,
    hvc.total_sales,
    hvc.order_count,
    COALESCE(item_sales.total_item_sales, 0) AS total_item_sales,
    CASE 
        WHEN hvc.order_count > 10 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS engagement_level
FROM 
    HighValueCustomers hvc
LEFT JOIN (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_item_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
) item_sales ON hvc.c_customer_id = item_sales.ws_bill_customer_sk
WHERE 
    hvc.total_sales IS NOT NULL
ORDER BY 
    hvc.total_sales DESC
LIMIT 50;
