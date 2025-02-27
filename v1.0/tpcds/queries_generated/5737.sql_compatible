
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        (COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0)) AS total_sales
    FROM 
        CustomerSales
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    ca.ca_city,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ws.ws_sold_date_sk >= 1000 AND ws.ws_sold_date_sk < 2000
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, ca.ca_city
ORDER BY 
    total_net_profit DESC;
