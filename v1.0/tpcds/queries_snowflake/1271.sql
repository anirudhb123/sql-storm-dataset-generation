
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_orders,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
TopCustomers AS (
    SELECT *
    FROM CustomerSales
    WHERE sales_rank <= 10
),
WarehouseSales AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_paid) AS total_warehouse_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
)

SELECT 
    TC.c_first_name,
    TC.c_last_name,
    TC.total_sales,
    COALESCE(WS.total_warehouse_sales, 0) AS total_warehouse_sales,
    (CASE 
         WHEN TC.total_sales > COALESCE(WS.total_warehouse_sales, 0) THEN 'Higher Sales'
         ELSE 'Lower or Equal Sales'
     END) AS sales_comparison,
    COUNT(DISTINCT s.s_store_sk) AS store_count,
    LISTAGG(DISTINCT s.s_store_name, ', ') WITHIN GROUP (ORDER BY s.s_store_name) AS store_names
FROM 
    TopCustomers TC
LEFT JOIN 
    store s ON s.s_store_sk IN (SELECT sr.sr_store_sk FROM store_returns sr WHERE sr.sr_customer_sk = TC.c_customer_sk)
LEFT JOIN 
    WarehouseSales WS ON WS.w_warehouse_sk IS NOT NULL
GROUP BY 
    TC.c_first_name, TC.c_last_name, TC.total_sales, WS.total_warehouse_sales
ORDER BY 
    TC.total_sales DESC;
