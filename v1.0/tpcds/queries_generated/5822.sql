
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        DENSE_RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_sales_price DESC) AS price_rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
TopSales AS (
    SELECT 
        rs.cs_item_sk, 
        SUM(rs.cs_sales_price * rs.cs_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank <= 5
    GROUP BY 
        rs.cs_item_sk
),
CustomerPurchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS customer_total_spent
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    cp.c_customer_sk,
    cp.customer_total_spent,
    ts.total_sales
FROM 
    CustomerPurchases cp
JOIN 
    TopSales ts ON cp.c_customer_sk = (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = ts.cs_item_sk LIMIT 1)
WHERE 
    cp.customer_total_spent > (SELECT AVG(customer_total_spent) FROM CustomerPurchases)
ORDER BY 
    cp.customer_total_spent DESC
LIMIT 10;
