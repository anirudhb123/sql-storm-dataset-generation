
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_customer_id
),
Demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM
        customer_demographics cd
),
SalesStatistics AS (
    SELECT
        COUNT(cs.c_customer_id) AS customer_count,
        AVG(cs.total_sales) AS average_sales,
        AVG(cs.order_count) AS average_orders,
        COUNT(DISTINCT cs.c_customer_id) FILTER (WHERE cs.total_sales > 5000) AS high_value_customers
    FROM
        CustomerSales cs
),
PopularItems AS (
    SELECT
        i.i_item_id,
        i.i_item_desc,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_sales
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_id, i.i_item_desc
    HAVING
        SUM(ws.ws_net_paid) > 10000
)
SELECT
    d.cd_gender,
    d.cd_marital_status,
    s.customer_count,
    s.average_sales,
    s.average_orders,
    p.i_item_desc,
    p.total_sales
FROM
    Demographics d
JOIN
    SalesStatistics s ON s.customer_count > 10
LEFT JOIN
    PopularItems p ON p.order_count > 100
ORDER BY
    s.average_sales DESC, p.total_sales DESC;
