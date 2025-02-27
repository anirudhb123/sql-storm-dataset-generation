
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_bill_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        r.total_sales,
        r.order_count
    FROM 
        RankedSales r
    JOIN 
        customer c ON r.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        r.sales_rank <= 10
),
SalesDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        tc.total_sales,
        tc.order_count,
        SUM(ws.ws_ext_ship_cost) AS total_shipping_cost
    FROM 
        TopCustomers tc
    JOIN 
        web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, tc.total_sales, tc.order_count
)
SELECT 
    sd.c_customer_id,
    sd.c_first_name,
    sd.c_last_name,
    sd.total_sales,
    sd.order_count,
    sd.total_shipping_cost,
    (sd.total_sales / NULLIF(sd.order_count, 0)) AS avg_sales_per_order
FROM 
    SalesDetails sd
ORDER BY 
    sd.total_sales DESC;
