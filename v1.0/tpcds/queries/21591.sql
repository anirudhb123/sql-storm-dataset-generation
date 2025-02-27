
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_sold_date_sk IN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2023 AND d.d_month_seq IN (2, 3) 
        )
),
FilteredSales AS (
    SELECT 
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 5
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT 
    tc.c_customer_sk,
    tc.order_count,
    tc.total_spent,
    STRING_AGG(CONCAT('Item: ', fs.ws_item_sk, ', Price: ', fs.ws_sales_price), '; ') AS item_sales_detail
FROM 
    TopCustomers tc
JOIN 
    FilteredSales fs ON fs.ws_order_number IN (
        SELECT DISTINCT ws.ws_order_number 
        FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = tc.c_customer_sk
    )
GROUP BY 
    tc.c_customer_sk, tc.order_count, tc.total_spent
ORDER BY 
    tc.total_spent DESC;
