
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(ws.ws_item_sk) AS item_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
),
SalesDetails AS (
    SELECT 
        tc.c_customer_id,
        tc.total_sales,
        tc.order_count,
        CASE 
            WHEN tc.total_sales > 1000 THEN 'High'
            WHEN tc.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        TopCustomers tc
    LEFT JOIN 
        web_sales ws ON tc.c_customer_id = ws.ws_bill_customer_sk
    WHERE 
        tc.sales_rank <= 10
    GROUP BY 
        tc.c_customer_id, tc.total_sales, tc.order_count
)
SELECT 
    sd.c_customer_id,
    sd.total_sales,
    sd.order_count,
    sd.sales_category,
    COALESCE(sd.total_discount, 0) AS total_discount,
    (SELECT AVG(total_sales) FROM CustomerSales) AS avg_sales,
    (SELECT COUNT(DISTINCT ws_item_sk) FROM web_sales) AS total_items_sold
FROM 
    SalesDetails sd
ORDER BY 
    sd.total_sales DESC;
