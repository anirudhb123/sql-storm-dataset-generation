
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        c.first_name,
        c.last_name,
        ws.order_number,
        ws_sold_date_sk,
        ws_quantity,
        ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws_ext_sales_price DESC) as rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        ws.bill_customer_sk IS NOT NULL
),
SalesSummary AS (
    SELECT 
        bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent,
        COUNT(order_number) AS total_orders,
        MIN(ws_sold_date_sk) AS first_order_date,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM 
        web_sales
    GROUP BY 
        bill_customer_sk
),
TopCustomers AS (
    SELECT 
        ss.bill_customer_sk,
        ss.total_spent,
        ss.total_orders,
        ss.first_order_date,
        ss.last_order_date
    FROM 
        SalesSummary ss
    JOIN 
        (SELECT 
            bill_customer_sk
         FROM 
            SalesSummary
         WHERE 
            total_spent > (SELECT AVG(total_spent) FROM SalesSummary)
         ORDER BY 
            total_spent DESC
         LIMIT 10) AS tc ON ss.bill_customer_sk = tc.bill_customer_sk
)
SELECT 
    tc.bill_customer_sk,
    c.first_name,
    c.last_name,
    tc.total_spent,
    tc.total_orders,
    tc.first_order_date,
    tc.last_order_date,
    COALESCE(r.rank_sales, 0) AS rank
FROM 
    TopCustomers tc
LEFT JOIN 
    RankedSales r ON tc.bill_customer_sk = r.bill_customer_sk AND r.rank_sales = 1
JOIN 
    customer c ON tc.bill_customer_sk = c.c_customer_sk
ORDER BY 
    tc.total_spent DESC;
