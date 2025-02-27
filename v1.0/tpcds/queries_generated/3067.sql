
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price, 
        ws_quantity, 
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL 
        AND ws_quantity > 0
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity_sold
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        SUM(rs.ws_quantity) > 100
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM 
        customer c 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_gender IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_gender
),
HighSpendingCustomers AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_gender, 
        cs.total_orders, 
        cs.total_spent
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT hsc.c_customer_sk) AS high_spender_count,
    AVG(hsc.total_spent) AS avg_spending
FROM 
    customer_address ca
JOIN 
    HighSpendingCustomers hsc ON ca.ca_address_sk = hsc.c_customer_sk
JOIN 
    TopSellingItems tsi ON tsi.ws_item_sk IN (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
    )
GROUP BY 
    ca.ca_city, 
    ca.ca_state
ORDER BY 
    high_spender_count DESC, 
    avg_spending DESC;
