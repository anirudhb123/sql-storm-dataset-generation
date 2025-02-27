
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_ext_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
),
TotalSales AS (
    SELECT 
        web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        RankedSales
    WHERE 
        rn <= 5
    GROUP BY 
        web_site_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
FinalResults AS (
    SELECT 
        t.web_site_sk,
        tc.total_sales,
        hc.c_first_name,
        hc.c_last_name,
        hc.cd_gender,
        tc.total_orders
    FROM 
        TotalSales tc
    JOIN 
        RankedSales t ON tc.web_site_sk = t.web_site_sk
    JOIN 
        HighValueCustomers hc ON hc.total_spent = (SELECT MAX(total_spent) FROM HighValueCustomers)
)
SELECT 
    fw.web_site_sk,
    fw.total_sales,
    fw.c_first_name,
    fw.c_last_name,
    fw.cd_gender,
    fw.total_orders
FROM 
    FinalResults fw
ORDER BY 
    fw.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
