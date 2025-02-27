
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        c.c_customer_id
)
SELECT 
    c.c_customer_id,
    cs.total_sales
FROM 
    CustomerSales cs
JOIN 
    customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
WHERE 
    cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
ORDER BY 
    cs.total_sales DESC
LIMIT 10;
