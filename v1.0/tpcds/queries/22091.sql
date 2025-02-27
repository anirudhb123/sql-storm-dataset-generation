
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
AggregateSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
SalesStatistics AS (
    SELECT 
        ac.ws_bill_customer_sk,
        CASE WHEN total_sales IS NULL THEN 0 ELSE total_sales END AS total_sales,
        order_count,
        AVG(total_sales) OVER () AS avg_sales
    FROM AggregateSales ac
    RIGHT JOIN RankedCustomers rc ON ac.ws_bill_customer_sk = rc.c_customer_sk
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    ss.total_sales,
    ss.order_count,
    ss.avg_sales,
    CASE 
        WHEN ss.total_sales > ss.avg_sales * 1.05 THEN 'High Spender'
        WHEN ss.total_sales < ss.avg_sales * 0.95 THEN 'Low Spender'
        ELSE 'Average Spender'
    END AS spending_category,
    COALESCE(ws_net_paid, 0) AS last_payment_net
FROM RankedCustomers rc
LEFT JOIN SalesStatistics ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = rc.c_customer_sk 
    AND ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = rc.c_customer_sk)
WHERE rc.purchase_rank = 1
  AND (rc.cd_credit_rating IS NULL OR rc.cd_credit_rating NOT LIKE '%poor%')
ORDER BY rc.cd_gender, total_sales DESC;
