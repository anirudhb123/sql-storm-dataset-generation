
WITH RankedSales AS (
    SELECT
        ws.bill_customer_sk,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_sales,
        SUM(ws.ext_sales_price) / COUNT(ws.order_number) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F' 
        AND ws.sold_date_sk BETWEEN 2400 AND 2406 
    GROUP BY
        ws.bill_customer_sk
),
SalesSummary AS (
    SELECT
        ra.bill_customer_sk,
        ra.total_orders,
        ra.total_sales,
        ra.avg_order_value,
        CASE 
            WHEN ra.total_orders > 100 THEN 'High Value Customer' 
            WHEN ra.total_orders BETWEEN 50 AND 100 THEN 'Medium Value Customer' 
            ELSE 'Low Value Customer' 
        END AS customer_value_segment
    FROM
        RankedSales ra
    WHERE
        ra.rank = 1
)
SELECT
    ss.customer_value_segment,
    COUNT(ss.bill_customer_sk) AS segment_count,
    SUM(ss.total_sales) AS total_sales_by_segment,
    AVG(ss.avg_order_value) AS avg_order_value_by_segment
FROM
    SalesSummary ss
GROUP BY
    ss.customer_value_segment
ORDER BY
    segment_count DESC;
