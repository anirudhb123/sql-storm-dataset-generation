
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                               AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_sk,
        c.total_sales,
        c.average_profit,
        c.total_orders,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    cu.total_sales,
    cu.average_profit,
    cu.total_orders
FROM 
    TopCustomers cu
WHERE 
    cu.sales_rank <= 10
ORDER BY 
    cu.total_sales DESC;
