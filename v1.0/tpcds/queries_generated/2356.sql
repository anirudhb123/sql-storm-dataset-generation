
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (
            SELECT 
                d_date_sk
            FROM 
                date_dim
            WHERE 
                d_year = 2023 AND d_month_seq IN (5, 6)
        )
), 
CustomerPurchases AS (
    SELECT 
        c_customer_sk,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        web_sales 
    JOIN 
        customer ON ws_bill_customer_sk = c_customer_sk
    WHERE 
        ws_sold_date_sk >= (
            SELECT 
                MIN(d_date_sk) 
            FROM 
                date_dim 
            WHERE 
                d_year = 2023 AND d_month_seq = 5
        )
    GROUP BY 
        c_customer_sk
),
TopCustomers AS (
    SELECT 
        c_customer_sk,
        total_spent,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        CustomerPurchases
    WHERE 
        total_spent IS NOT NULL
)
SELECT 
    ca.city,
    COUNT(DISTINCT rs.ws_order_number) AS total_orders,
    AVG(rs.ws_sales_price) AS avg_sales_price,
    MAX(rs.ws_quantity) AS max_quantity_sold,
    SUM(CASE WHEN tc.customer_rank <= 10 THEN 1 ELSE 0 END) AS top_customer_order_count
FROM 
    RankedSales rs
JOIN 
    customer_address ca ON rs.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN 
    TopCustomers tc ON rs.ws_bill_customer_sk = tc.c_customer_sk
WHERE 
    rs.price_rank = 1
GROUP BY 
    ca.city
HAVING 
    COUNT(DISTINCT rs.ws_order_number) > 5
ORDER BY 
    avg_sales_price DESC
LIMIT 20;
