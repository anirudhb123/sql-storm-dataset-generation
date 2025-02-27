
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451182 AND 2451351 
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON c.c_customer_id = cs.c_customer_id
    WHERE 
        cs.total_sales IS NOT NULL
),
FinalReport AS (
    SELECT 
        tc.customer_id,
        cs.total_sales,
        cs.order_count,
        cs.avg_order_value,
        CASE 
            WHEN cs.avg_order_value IS NULL THEN 'N/A'
            ELSE CAST(cs.avg_order_value AS VARCHAR(20)) -- Using standard SQL for formatting
        END AS formatted_avg_order_value,
        CASE 
            WHEN rank <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS customer_category
    FROM 
        CustomerSales cs
    JOIN 
        TopCustomers tc ON cs.c_customer_id = tc.customer_id
)
SELECT 
    fr.customer_id,
    fr.total_sales,
    fr.order_count,
    fr.formatted_avg_order_value,
    fr.customer_category
FROM 
    FinalReport fr
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_id = fr.customer_id)
WHERE
    (cd.cd_gender = 'F' OR cd.cd_gender IS NULL) 
ORDER BY 
    fr.total_sales DESC;
