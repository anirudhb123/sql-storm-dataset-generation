
WITH SalesData AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS state_rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 AND d.d_moy BETWEEN 1 AND 6
    GROUP BY
        c.c_customer_id, ca.ca_state
),
TopSales AS (
    SELECT
        state,
        total_sales,
        total_orders,
        avg_sales_price
    FROM SalesData
    WHERE state_rank = 1
)
SELECT
    ca_state,
    COUNT(*) AS customer_count,
    SUM(total_sales) AS total_sales_by_state,
    AVG(avg_sales_price) AS avg_sales_price_by_state
FROM
    SalesData
GROUP BY
    ca_state
ORDER BY 
    total_sales_by_state DESC
LIMIT 10;
