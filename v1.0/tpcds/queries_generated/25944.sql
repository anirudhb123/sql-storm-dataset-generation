
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        rc.cd_gender, 
        rc.cd_marital_status
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10 AND rc.cd_gender = 'M'
),
SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sales_price,
        ws.ws_quantity,
        c.c_customer_id
    FROM 
        web_sales ws
    JOIN 
        FilteredCustomers c ON ws.ws_bill_customer_sk = c.c_customer_id::integer
)
SELECT 
    COUNT(*) AS total_orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    SUM(ws.ws_quantity) AS total_quantity
FROM 
    SalesData ws
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
    AND d.d_month_seq IN (1, 2, 3)
GROUP BY 
    d.d_month_seq
ORDER BY 
    d.d_month_seq;
