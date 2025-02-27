
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        cs.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
RankedCustomers AS (
    SELECT 
        hvc.*,
        RANK() OVER (ORDER BY hvc.total_sales DESC) AS sales_rank
    FROM 
        HighValueCustomers hvc
)

SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.total_sales,
    rc.order_count,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    rc.sales_rank
FROM 
    RankedCustomers rc
WHERE 
    rc.sales_rank <= 10
ORDER BY 
    rc.total_sales DESC;
