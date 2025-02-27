
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        MAX(ws.ws_ship_date_sk) AS last_purchase_date
    FROM 
        customer c
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_sales,
        cs.last_purchase_date
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
RecentHighValueCustomers AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.c_first_name,
        hvc.c_last_name,
        hvc.total_orders,
        hvc.total_sales,
        hvc.last_purchase_date
    FROM 
        HighValueCustomers hvc
    WHERE 
        hvc.last_purchase_date > (SELECT MAX(d.d_date) - INTERVAL '30 DAY' FROM date_dim d)
)
SELECT 
    rhvc.c_customer_sk,
    rhvc.c_first_name,
    rhvc.c_last_name,
    rhvc.total_orders,
    rhvc.total_sales,
    rhvc.last_purchase_date,
    CASE 
        WHEN rhvc.total_sales > 1000 THEN 'Loyal Customer'
        WHEN rhvc.total_sales BETWEEN 500 AND 1000 THEN 'Frequent Shopper'
        ELSE 'New Customer'
    END AS customer_category
FROM 
    RecentHighValueCustomers rhvc
ORDER BY 
    rhvc.total_sales DESC
LIMIT 100;
