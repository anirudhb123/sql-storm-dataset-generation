
WITH customer_metrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_age_band,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_age_band
),
holiday_sales AS (
    SELECT
        d.d_date_id,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales
    FROM
        date_dim d
    JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_holiday = 'Y'
    GROUP BY 
        d.d_date_id
),
high_value_customers AS (
    SELECT 
        cm.c_customer_sk,
        cm.c_first_name,
        cm.c_last_name,
        cm.total_orders,
        cm.total_spent,
        cm.avg_order_value
    FROM 
        customer_metrics cm
    WHERE 
        cm.total_spent > (SELECT AVG(total_spent) FROM customer_metrics)
),
combined_sales AS (
    SELECT 
        'Website' AS sales_channel,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
    UNION ALL
    SELECT 
        'Store' AS sales_channel,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_sold_date_sk
)
SELECT 
    cm.c_first_name,
    cm.c_last_name,
    cm.total_orders,
    cm.total_spent,
    hs.total_store_sales,
    cv.sales_channel,
    cv.total_sales
FROM 
    high_value_customers cm
LEFT JOIN 
    holiday_sales hs ON hs.total_store_sales IS NOT NULL
JOIN 
    combined_sales cv ON cv.total_sales IS NOT NULL
WHERE 
    (cm.total_spent IS NOT NULL OR cm.total_orders IS NOT NULL)
    AND (cm.total_orders > 0 OR cm.total_spent > 0)
ORDER BY 
    cm.total_spent DESC, hs.total_store_sales ASC, cv.sales_channel;
