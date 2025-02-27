
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    ORDER BY 
        cs.total_sales DESC
    LIMIT 10
), 
SalesDetails AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_discount_amt,
        ws.ws_ext_tax
    FROM 
        TopCustomers tc
    JOIN 
        web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
)
SELECT 
    sd.c_customer_sk,
    sd.c_first_name,
    sd.c_last_name,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_sales_price) AS total_sales,
    SUM(sd.ws_discount_amt) AS total_discount,
    SUM(sd.ws_ext_tax) AS total_tax
FROM 
    SalesDetails sd
GROUP BY 
    sd.c_customer_sk, sd.c_first_name, sd.c_last_name
ORDER BY 
    total_sales DESC;
