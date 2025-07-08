
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        dd.d_year = 2022 
    GROUP BY 
        ws.ws_sold_date_sk
),
SalesSummary AS (
    SELECT 
        d.d_date AS sale_date,
        sd.total_sales,
        sd.total_orders,
        sd.average_order_value,
        sd.total_quantity_sold,
        cd.cd_gender,
        cd.cd_education_status
    FROM 
        SalesData sd
    JOIN 
        date_dim d ON sd.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON c.c_current_cdemo_sk = (SELECT cd_demo_sk FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk)
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    ss.sale_date,
    ss.total_sales,
    ss.total_orders,
    ss.average_order_value,
    ss.total_quantity_sold,
    ss.cd_gender,
    ss.cd_education_status
FROM 
    SalesSummary ss
ORDER BY 
    ss.sale_date ASC;
