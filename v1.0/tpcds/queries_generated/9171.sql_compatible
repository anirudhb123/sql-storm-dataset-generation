
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        r.total_sales
    FROM 
        customer c
    JOIN 
        RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
    WHERE 
        r.sales_rank <= 10
),
SalesDetails AS (
    SELECT 
        tc.c_customer_id, 
        tc.c_first_name, 
        tc.c_last_name, 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        d.d_date
    FROM 
        TopCustomers tc
    JOIN 
        web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    sd.c_customer_id,
    sd.c_first_name,
    sd.c_last_name,
    COUNT(DISTINCT sd.ws_order_number) AS total_orders,
    SUM(sd.ws_ext_sales_price) AS total_spent,
    MIN(d.d_date) AS first_purchase_date,
    MAX(d.d_date) AS last_purchase_date
FROM 
    SalesDetails sd
GROUP BY 
    sd.c_customer_id, 
    sd.c_first_name, 
    sd.c_last_name
ORDER BY 
    total_spent DESC;
