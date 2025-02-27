
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_sold_date_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_ext_sales_price) > 100000
), 
CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_spent,
        COUNT(ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        cs.total_spent,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        CustomerSpend cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                CustomerSpend
        )
)
SELECT 
    s.ws_sold_date_sk,
    s.total_sales,
    tc.c_customer_id,
    tc.total_spent,
    tc.order_count,
    COALESCE(sm.sm_type, 'Unknown') AS shipping_method
FROM 
    SalesCTE s
JOIN 
    TopCustomers tc ON s.ws_sold_date_sk IN 
    (SELECT ws_sold_date_sk FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_id)
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (
        SELECT 
            ws_ship_mode_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = tc.c_customer_id 
        LIMIT 1
    )
WHERE 
    s.sales_rank <= 10
ORDER BY 
    s.ws_sold_date_sk DESC, 
    tc.total_spent DESC;
