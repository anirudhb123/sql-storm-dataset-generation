
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(d.d_date) AS last_purchase_date
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.last_purchase_date,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS cs
)
SELECT 
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.total_sales,
    t.order_count,
    t.last_purchase_date,
    d.d_year,
    d.d_month,
    d.d_day,
    COUNT(DISTINCT sr.sr_item_sk) AS return_count,
    SUM(sr.sr_return_amt) AS total_return_amount
FROM 
    TopCustomers AS t
LEFT JOIN 
    store_returns AS sr ON t.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    date_dim AS d ON sr.sr_returned_date_sk = d.d_date_sk
WHERE 
    t.sales_rank <= 10
GROUP BY 
    t.c_customer_sk, t.c_first_name, t.c_last_name, t.total_sales, 
    t.order_count, t.last_purchase_date, d.d_year, d.d_month, d.d_day
ORDER BY 
    t.total_sales DESC;
