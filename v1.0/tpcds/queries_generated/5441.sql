
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim)) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim))
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
TopSales AS (
    SELECT 
        ca.city AS customer_city,
        SUM(rs.total_quantity) AS total_quantity,
        SUM(rs.total_sales) AS total_sales,
        COUNT(DISTINCT rs.ws_bill_customer_sk) AS unique_customers
    FROM 
        RankedSales rs
    JOIN 
        customer c ON rs.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        rs.rank = 1
    GROUP BY 
        ca.city
)
SELECT 
    t.customer_city,
    t.total_quantity,
    t.total_sales,
    t.unique_customers,
    (t.total_sales / NULLIF(t.total_quantity, 0)) AS avg_sales_per_item
FROM 
    TopSales t
ORDER BY 
    t.total_sales DESC
LIMIT 10;
