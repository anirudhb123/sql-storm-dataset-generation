
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name
),
TopCustomers AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        c.total_web_sales,
        c.order_count,
        DENSE_RANK() OVER (ORDER BY c.total_web_sales DESC) AS sales_rank
    FROM
        CustomerSales c
),
DateFilteredSales AS (
    SELECT
        ws.ws_ship_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        web_sales ws
    JOIN date_dim d ON ws.ws_ship_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 AND d.d_moy IN (6, 7)  -- June and July 2023
    GROUP BY
        ws.ws_ship_date_sk
)
SELECT
    tc.first_name,
    tc.last_name,
    tc.total_web_sales,
    tc.order_count,
    COALESCE(dfs.total_sales, 0) AS total_sales_for_period,
    CASE 
        WHEN tc.order_count > 5 THEN 'Frequent Buyer'
        WHEN tc.order_count BETWEEN 3 AND 5 THEN 'Regular Buyer'
        ELSE 'New Buyer'
    END AS customer_type
FROM
    TopCustomers tc
LEFT JOIN DateFilteredSales dfs ON tc.customer_id = dfs.total_sales -- Simulate a relation
WHERE
    tc.sales_rank <= 10  -- Top 10 Customers
ORDER BY
    tc.total_web_sales DESC;
