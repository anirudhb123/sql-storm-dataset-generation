
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity,
        AVG(sr_return_amt_inc_tax) OVER (PARTITION BY c.c_customer_sk) AS avg_return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sr_return_amt) DESC) AS gender_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_return_amount DESC) AS return_rank
    FROM 
        CustomerStats
),
DailyActivity AS (
    SELECT 
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(CASE WHEN ws.ws_quantity IS NOT NULL THEN ws.ws_quantity ELSE 0 END) AS total_quantity
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.marital_status,
    tc.total_returns,
    tc.total_return_amount,
    da.d_date,
    da.total_sales,
    da.total_orders,
    da.total_quantity
FROM 
    TopCustomers tc
JOIN 
    DailyActivity da ON da.total_sales > 1000
WHERE 
    tc.gender_rank = 1
ORDER BY 
    tc.total_return_amount DESC, da.d_date DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
