
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_id
), 
CustomerDemo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
), 
SalesByGender AS (
    SELECT 
        cd.cd_gender,
        AVG(cs.total_sales) AS avg_sales,
        AVG(cs.order_count) AS avg_orders,
        AVG(cs.total_profit) AS avg_profit
    FROM 
        CustomerSales cs
    JOIN 
        CustomerDemo cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
) 
SELECT 
    sg.cd_gender,
    sg.avg_sales,
    sg.avg_orders,
    sg.avg_profit,
    CASE 
        WHEN sg.avg_sales > 1000 THEN 'High Spenders'
        WHEN sg.avg_sales BETWEEN 500 AND 1000 THEN 'Medium Spenders'
        ELSE 'Low Spenders' 
    END AS spending_category
FROM 
    SalesByGender sg
ORDER BY 
    sg.avg_sales DESC;
