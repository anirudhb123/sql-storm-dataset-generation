
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        LOWER(c.c_first_name) AS first_name,
        LOWER(c.c_last_name) AS last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, LOWER(c.c_first_name), LOWER(c.c_last_name)
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.first_name,
        cs.last_name,
        cs.total_sales,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
),
SalesDetails AS (
    SELECT 
        tc.first_name,
        tc.last_name,
        tc.total_sales,
        tc.total_orders,
        d.d_date AS order_date,
        SUM(ws.ws_net_profit) AS daily_net_profit
    FROM 
        TopCustomers tc
    JOIN 
        web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        tc.sales_rank <= 10
    GROUP BY 
        tc.first_name, tc.last_name, tc.total_sales, tc.total_orders, d.d_date
)
SELECT 
    sd.first_name,
    sd.last_name,
    sd.total_sales,
    sd.total_orders,
    sd.order_date,
    sd.daily_net_profit,
    CONCAT(sd.first_name, ' ', sd.last_name, ' spent $', ROUND(sd.total_sales, 2), ' over ', sd.total_orders, ' orders on ', TO_CHAR(sd.order_date, 'Month DD, YYYY')) AS sales_summary
FROM 
    SalesDetails sd
ORDER BY 
    sd.total_sales DESC, sd.order_date;
