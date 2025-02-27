
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_month, c.c_birth_year
    HAVING 
        COUNT(DISTINCT ws_order_number) > 5
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_month,
        c.c_birth_year,
        sh.total_orders + 1,
        sh.total_profit + (CASE WHEN ws.ws_net_profit IS NOT NULL THEN ws.ws_net_profit ELSE 0 END)
    FROM 
        SalesHierarchy sh
    JOIN 
        web_sales ws ON sh.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer c ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        sh.total_orders < 10
),
FirstSales AS (
    SELECT 
        c.c_customer_sk,
        MIN(ws.ws_sold_date_sk) AS first_sales_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        a.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count,
        fs.first_sales_date
    FROM 
        customer c
    LEFT JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN 
        FirstSales fs ON c.c_customer_sk = fs.c_customer_sk
)
SELECT 
    cd.c_customer_sk,
    cd.ca_city,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    cd.vehicle_count,
    sh.total_orders,
    sh.total_profit
FROM 
    CustomerDetails cd
JOIN 
    SalesHierarchy sh ON cd.c_customer_sk = sh.c_customer_sk
ORDER BY 
    sh.total_profit DESC,
    cd.c_customer_sk;
