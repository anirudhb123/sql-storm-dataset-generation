
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_id
), TopCustomers AS (
    SELECT
        c.c_customer_id,
        cs.total_sales,
        cs.total_orders
    FROM
        CustomerSales cs
    JOIN
        customer c ON cs.c_customer_id = c.c_customer_id
    WHERE
        cs.sales_rank <= 10
)
SELECT
    tc.c_customer_id,
    tc.total_sales,
    tc.total_orders,
    cd.cd_gender,
    cd.cd_marital_status,
    ca.ca_city,
    ca.ca_state
FROM
    TopCustomers tc
JOIN
    customer_demographics cd ON tc.c_customer_id = cd.cd_demo_sk
JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY
    tc.total_sales DESC;
