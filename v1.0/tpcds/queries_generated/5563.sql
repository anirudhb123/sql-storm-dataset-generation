
WITH CustomerPurchases AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_spent_per_order,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450300  -- Filtering by a date range
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
OutlierCustomers AS (
    SELECT 
        *, 
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY total_spent) OVER () AS spend_threshold
    FROM 
        CustomerPurchases
)
SELECT 
    oc.c_customer_id,
    oc.total_orders,
    oc.total_spent,
    oc.avg_spent_per_order,
    oc.cd_gender,
    oc.cd_marital_status,
    'High Value' AS customer_type
FROM 
    OutlierCustomers AS oc
WHERE 
    oc.total_spent > oc.spend_threshold
ORDER BY 
    oc.total_spent DESC
LIMIT 100;
