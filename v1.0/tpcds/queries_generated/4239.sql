
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(ss_ext_sales_price), 0) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS online_orders,
        COUNT(DISTINCT sr_ticket_number) AS store_returns,
        COUNT(DISTINCT cr_order_number) AS catalog_returns,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(ss_ext_sales_price), 0) DESC) AS revenue_rank
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.online_orders,
        cs.store_returns,
        cs.catalog_returns,
        cs.revenue_rank
    FROM 
        customer_summary cs
    WHERE 
        cs.revenue_rank <= 10
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.online_orders,
    tc.store_returns,
    tc.catalog_returns,
    CASE 
        WHEN tc.store_returns > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_store_return,
    COALESCE((SELECT AVG(total_sales) FROM customer_summary), 0) AS average_sales,
    STRING_AGG(CONCAT(sd.channel, ': ', sd.channel_count)) AS sales_channels
FROM 
    top_customers tc
LEFT JOIN (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        'web_sales' AS channel,
        COUNT(ws_order_number) AS channel_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    UNION ALL
    SELECT 
        ss_customer_sk AS customer_sk,
        'store_sales' AS channel,
        COUNT(ss_ticket_number) AS channel_count
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
) sd ON tc.c_customer_sk = sd.customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.total_sales, tc.online_orders, tc.store_returns, tc.catalog_returns
ORDER BY 
    tc.total_sales DESC;
