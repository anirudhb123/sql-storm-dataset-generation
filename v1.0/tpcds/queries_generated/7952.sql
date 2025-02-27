
WITH customer_stats AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.cs_sales_price) AS total_sales,
        AVG(cs.cs_sales_price) AS avg_sales,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    JOIN
        date_dim d ON cs.ss_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
),
sales_comparison AS (
    SELECT
        ca.ca_state,
        SUM(ws.ws_sales_price) AS online_sales,
        SUM(ss.ss_sales_price) AS store_sales
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        ca.ca_state
),
final_report AS (
    SELECT
        cs.cd_gender,
        cs.cd_marital_status,
        sc.ca_state,
        cs.customer_count,
        cs.total_sales,
        cs.avg_sales,
        sc.online_sales,
        sc.store_sales
    FROM
        customer_stats cs
    JOIN
        sales_comparison sc ON cs.customer_count > 100
)
SELECT
    cd_gender,
    cd_marital_status,
    ca_state,
    customer_count,
    total_sales,
    avg_sales,
    online_sales,
    store_sales,
    (online_sales + store_sales) AS total_revenue,
    (total_sales / NULLIF(customer_count, 0)) AS sales_per_customer
FROM
    final_report
ORDER BY
    total_revenue DESC
LIMIT 10;
