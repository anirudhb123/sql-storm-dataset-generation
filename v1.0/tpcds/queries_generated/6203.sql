
WITH Customer_Sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Sales_Statistics AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY cs.last_purchase_date DESC) AS recency_rank
    FROM 
        Customer_Sales cs
),
Top_Customers AS (
    SELECT
        s.c_customer_sk,
        s.c_first_name,
        s.c_last_name,
        s.total_sales,
        s.order_count,
        s.sales_rank,
        s.recency_rank
    FROM
        Sales_Statistics s
    WHERE
        s.sales_rank <= 10
)
SELECT
    c.c_city,
    COUNT(tc.c_customer_sk) AS top_customer_count,
    AVG(tc.total_sales) AS avg_sales,
    SUM(tc.order_count) AS total_orders
FROM
    Top_Customers tc
JOIN
    customer_address ca ON tc.c_customer_sk = ca.ca_address_sk
JOIN
    customer c ON tc.c_customer_sk = c.c_customer_sk
GROUP BY
    c.c_city
ORDER BY
    top_customer_count DESC;
