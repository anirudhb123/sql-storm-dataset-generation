
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales IS NOT NULL
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_sales) AS total_sales
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        HighValueCustomers hvc ON c.c_customer_sk = hvc.c_customer_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_sales,
    hvc.order_count,
    cd.cd_gender,
    cd.cd_marital_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    CustomerDemographics cd ON hvc.c_customer_sk = cd.cd_demo_sk
WHERE 
    hvc.sales_rank <= 10
ORDER BY 
    hvc.total_sales DESC;
