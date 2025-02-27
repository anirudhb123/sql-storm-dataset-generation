
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS average_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_sales) AS total_sales,
        COUNT(cs.order_count) AS total_orders,
        AVG(cs.average_order_value) AS average_order_value
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
SalesByDate AS (
    SELECT 
        dd.d_year,
        dd.d_month_seq,
        SUM(ws.ws_net_paid) AS monthly_sales
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        dd.d_year, dd.d_month_seq
)
SELECT 
    sd.d_year,
    sd.d_month_seq,
    sbd.cd_gender,
    sbd.cd_marital_status,
    sbd.total_sales,
    sbd.total_orders,
    sbd.average_order_value
FROM 
    SalesByDemographics sbd
JOIN 
    SalesByDate sd ON sbd.total_sales > 10000
WHERE 
    sbd.total_orders > 50
ORDER BY 
    sd.d_year DESC, sd.d_month_seq DESC;
