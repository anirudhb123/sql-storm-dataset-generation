
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(NULLIF(cd.cd_credit_rating, ''), 'UNKNOWN') AS credit_rating,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'No Dependents'
            WHEN cd.cd_dep_count = 0 THEN 'No Dependents'
            ELSE CONCAT(cd.cd_dep_count, ' Dependents')
        END AS dependent_status,
        RANK() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_paid) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
ReturnsSummary AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_net_loss) AS total_return_loss
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.c_first_name,
    cs.c_last_name,
    cs.dependent_status,
    ss.total_profit,
    ss.total_orders,
    ss.avg_order_value,
    COALESCE(rs.total_return_loss, 0) AS total_return_loss,
    CASE 
        WHEN ss.total_profit > 5000 THEN 'High Value Customer'
        WHEN ss.total_profit BETWEEN 1000 AND 5000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category,
    d.d_day_name,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    STRING_AGG(CONCAT(i.i_item_id, ': ', i.i_item_desc) ORDER BY i.i_item_id) AS purchased_items
FROM 
    CustomerSummary cs
LEFT JOIN 
    SalesSummary ss ON cs.c_customer_id = ss.ws_bill_customer_sk
LEFT JOIN 
    ReturnsSummary rs ON cs.c_customer_id = rs.wr_returning_customer_sk
LEFT JOIN 
    date_dim d ON d.d_date_sk = (
        SELECT MAX(ws_sold_date_sk)
        FROM web_sales
        WHERE ws_bill_customer_sk = cs.c_customer_id
    )
LEFT JOIN 
    web_sales ws ON cs.c_customer_id = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    cs.gender_rank <= 3
GROUP BY 
    cs.c_customer_id, cs.c_first_name, cs.c_last_name, 
    cs.dependent_status, ss.total_profit, ss.total_orders, 
    ss.avg_order_value, rs.total_return_loss, d.d_day_name
ORDER BY 
    total_profit DESC, customer_value_category, cs.c_last_name;
