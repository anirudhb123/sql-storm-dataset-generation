
WITH ActiveCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_email_address, cd.cd_gender, cd.cd_marital_status
    HAVING 
        total_orders > 10
),
RecentActivities AS (
    SELECT 
        c.c_customer_sk,
        MAX(dw.d_date) AS last_activity_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
    GROUP BY 
        c.c_customer_sk
),
CustomerMetrics AS (
    SELECT 
        ac.c_customer_sk,
        ac.c_email_address,
        ac.cd_gender,
        ac.cd_marital_status,
        ac.total_orders,
        ac.total_profit,
        ra.last_activity_date,
        DATEDIFF(CURRENT_DATE, ra.last_activity_date) AS days_since_last_activity
    FROM 
        ActiveCustomers ac
    JOIN 
        RecentActivities ra ON ac.c_customer_sk = ra.c_customer_sk
    WHERE 
        DATEDIFF(CURRENT_DATE, ra.last_activity_date) >= 30
)
SELECT 
    cm.c_customer_sk,
    cm.c_email_address,
    cm.cd_gender,
    COALESCE(cm.cd_marital_status, 'Undefined') AS marital_status,
    cm.total_orders,
    cm.total_profit,
    cm.days_since_last_activity,
    CASE 
        WHEN cm.total_profit > 1000 THEN 'High Value'
        WHEN cm.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    ROW_NUMBER() OVER (PARTITION BY cm.cd_gender ORDER BY cm.total_profit DESC) AS rank_within_gender
FROM 
    CustomerMetrics cm
ORDER BY 
    cm.days_since_last_activity DESC, cm.total_profit DESC;

WITH RECURSIVE DateSequence AS (
    SELECT 
        d.d_date_sk, d.d_date
    FROM 
        date_dim d
    WHERE 
        d.d_date > CURRENT_DATE - INTERVAL '1 YEAR'
    UNION ALL
    SELECT 
        d.d_date_sk, d.d_date + INTERVAL '1 DAY'
    FROM 
        DateSequence ds
    JOIN 
        date_dim d ON ds.d_date + INTERVAL '1 DAY' = d.d_date
)
SELECT 
    ds.d_date,
    COUNT(DISTINCT ws.ws_order_number) AS total_sales,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    DateSequence ds
LEFT JOIN 
    web_sales ws ON ds.d_date_sk = ws.ws_sold_date_sk
GROUP BY 
    ds.d_date
ORDER BY 
    ds.d_date;
