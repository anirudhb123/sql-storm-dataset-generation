
WITH SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_ship_mode_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_ship_mode_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT o.ws_order_number) AS total_orders,
        SUM(o.ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status
),
HighSpenders AS (
    SELECT 
        c.customer_sk, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_education_status,
        total_spent
    FROM 
        CustomerData cd
    JOIN 
        CustomerData c ON c.total_spent >= 500
),
SaleSummary AS (
    SELECT 
        sd.ws_ship_mode_sk, 
        SUM(sd.total_quantity) AS total_units_sold,
        SUM(sd.total_sales) AS total_revenue
    FROM 
        SalesData sd
    JOIN 
        HighSpenders hs ON sd.ws_sold_date_sk = hs.customer_sk
    GROUP BY 
        sd.ws_ship_mode_sk
)
SELECT 
    sm.sm_ship_mode_id,
    sm.sm_type,
    ss.total_units_sold,
    ss.total_revenue
FROM 
    SaleSummary ss
JOIN 
    ship_mode sm ON ss.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY 
    ss.total_revenue DESC;
