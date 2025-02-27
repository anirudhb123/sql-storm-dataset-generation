
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_paid) AS total_sales,
        COUNT(*) AS total_transactions,
        COUNT(DISTINCT ws.order_number) AS unique_orders,
        AVG(ws.net_profit) AS average_profit,
        MAX(ws.ship_date_sk) AS last_purchase_date
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022 AND cd.cd_marital_status = 'M'
    GROUP BY 
        ws.bill_customer_sk
),
TopCustomers AS (
    SELECT 
        bill_customer_sk,
        total_sales,
        total_transactions,
        unique_orders,
        average_profit,
        last_purchase_date,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    tc.bill_customer_sk,
    c.c_first_name,
    c.c_last_name,
    tc.total_sales,
    tc.total_transactions,
    tc.unique_orders,
    tc.average_profit,
    tc.last_purchase_date
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.bill_customer_sk = c.c_customer_sk
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
