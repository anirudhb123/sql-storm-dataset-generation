
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.item_sk
),
TopSales AS (
    SELECT 
        rs.web_site_sk,
        rs.item_sk,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesByCustomer AS (
    SELECT 
        cd.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_customer_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cd.c_customer_sk
)
SELECT 
    ts.web_site_sk,
    ts.item_sk,
    ts.total_quantity,
    ts.total_sales,
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_education_status,
    c.cd_purchase_estimate,
    c.cd_credit_rating,
    c.cd_dep_count,
    sbc.total_customer_spent,
    sbc.total_orders,
    sbc.avg_order_value
FROM 
    TopSales ts
JOIN 
    CustomerDetails c ON c.c_customer_sk IN (SELECT DISTINCT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.item_sk = ts.item_sk)
JOIN 
    SalesByCustomer sbc ON sbc.c_customer_sk = c.c_customer_sk
ORDER BY 
    ts.total_sales DESC;
