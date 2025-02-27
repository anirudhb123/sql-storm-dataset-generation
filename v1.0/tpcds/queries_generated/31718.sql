
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_sold_date_sk

    UNION ALL

    SELECT 
        s_store_sk,
        ss_sold_date_sk,
        total_sales + COALESCE(ws_total_sales, 0) AS total_sales,
        total_transactions + COALESCE(ws_total_transactions, 0) AS total_transactions
    FROM 
        SalesCTE
    LEFT JOIN (
        SELECT 
            ws_ship_date_sk,
            ws_warehouse_sk,
            SUM(ws_sales_price) AS ws_total_sales,
            COUNT(ws_order_number) AS ws_total_transactions
        FROM 
            web_sales
        GROUP BY 
            ws_ship_date_sk, ws_warehouse_sk
    ) AS WebSales ON WebSales.ws_warehouse_sk = SalesCTE.s_store_sk AND WebSales.ws_ship_date_sk = SalesCTE.ss_sold_date_sk
    WHERE
        SalesCTE.total_transactions < 100
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0)) AS total_customer_spend,
        d.d_year,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        c.c_customer_sk, d.d_year, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        total_customer_spend,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_customer_spend DESC) AS spending_rank
    FROM 
        CustomerSales
)

SELECT 
    c.c_customer_sk,
    tc.total_customer_spend,
    tc.spending_rank,
    CONCAT('CustomerID: ', c.c_customer_id, ', Gender: ', cd.cd_gender) AS customer_info,
    CASE 
        WHEN cd.cd_marital_status IS NULL THEN 'Not specified'
        ELSE cd.cd_marital_status 
    END AS marital_status
FROM 
    TopCustomers tc
JOIN customer c ON tc.c_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    tc.spending_rank <= 10
ORDER BY 
    tc.total_customer_spend DESC;
