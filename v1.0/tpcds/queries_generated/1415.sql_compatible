
WITH CustomerPurchase AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
HighSpenders AS (
    SELECT 
        * 
    FROM 
        CustomerPurchase 
    WHERE 
        total_sales > 10000
), 
StoresWithSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_ext_sales_price) AS store_revenue
    FROM 
        store s 
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    c.cd_gender, 
    c.total_sales AS customer_sales,
    s.store_revenue,
    H.HIGH_CUSTOMER_RANK
FROM 
    HighSpenders c
JOIN 
    (SELECT 
         store_revenue,
         ROW_NUMBER() OVER (ORDER BY store_revenue DESC) AS HIGH_CUSTOMER_RANK 
     FROM 
         StoresWithSales) H ON H.store_revenue = (
         SELECT 
             MIN(store_revenue) 
         FROM 
             StoresWithSales
         WHERE 
             store_revenue > (SELECT AVG(store_revenue) FROM StoresWithSales)
     )
ORDER BY 
    c.total_sales DESC, 
    c.c_first_name;
