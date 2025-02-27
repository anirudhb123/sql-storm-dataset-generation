
WITH CustomerPurchaseSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
), 
DemographicStats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        AVG(cps.total_spent) AS avg_spent_per_demo,
        SUM(cps.total_orders) AS total_orders_per_demo,
        SUM(cps.unique_items_purchased) AS total_unique_items
    FROM 
        customer_demographics cd
    JOIN 
        CustomerPurchaseSummary cps ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status
), 
TimeFrameAggregates AS (
    SELECT 
        dd.d_year,
        SUM(cps.total_spent) AS total_spent_per_year,
        COUNT(cps.total_orders) AS total_orders_per_year
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    JOIN 
        CustomerPurchaseSummary cps ON ws.ws_bill_customer_sk = cps.c_customer_sk
    GROUP BY 
        dd.d_year
)
SELECT 
    ds.cd_gender,
    ds.cd_marital_status,
    tf.total_spent_per_year,
    tf.total_orders_per_year,
    ds.avg_spent_per_demo,
    ds.total_orders_per_demo,
    ds.total_unique_items
FROM 
    DemographicStats ds
JOIN 
    TimeFrameAggregates tf ON ds.total_orders_per_demo > 0
ORDER BY 
    ds.cd_gender, ds.cd_marital_status;
