
WITH RankedSales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
SalesAnalysis AS (
    SELECT
        rs.ws_order_number,
        rs.ws_item_sk,
        rs.ws_sales_price,
        COALESCE(AVG(ws_net_paid) OVER (PARTITION BY ws_item_sk ORDER BY ws_item_sk ROWS BETWEEN 1 PRECEDING AND CURRENT ROW), 0) AS rolling_avg_net_paid,
        CASE 
            WHEN rs.ws_net_paid IS NULL THEN 'Missing'
            WHEN rs.ws_net_paid > 1000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS value_category
    FROM
        RankedSales rs
    WHERE
        rs.rank = 1
),
CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(sa.ws_net_paid) AS total_spent,
        COUNT(sa.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN web_sales sa ON c.c_customer_sk = sa.ws_ship_customer_sk
    GROUP BY
        c.c_customer_id
)
SELECT
    c.c_customer_id,
    cs.total_spent,
    cs.total_orders,
    COALESCE(d.d_day_name, 'Unknown Day') AS transaction_day,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    STRING_AGG(CONCAT('[Item: ', rs.ws_item_sk, ', Price: ', rs.ws_sales_price, ', Category: ', rs.value_category, ']'), ', ') AS sales_summary
FROM
    CustomerSales cs
LEFT JOIN customer c ON cs.c_customer_id = c.c_customer_id
LEFT JOIN SalesAnalysis rs ON cs.total_orders > 0
LEFT JOIN date_dim d ON d.d_date_sk = (SELECT TOP 1 d_date_sk FROM date_dim ORDER BY d_date DESC)
WHERE
    cs.total_spent IS NOT NULL
GROUP BY
    c.c_customer_id, cs.total_spent, cs.total_orders, d.d_day_name
ORDER BY
    cs.total_spent DESC;
