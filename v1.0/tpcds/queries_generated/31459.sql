
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk >= 20230101
    GROUP BY ws_item_sk
    
    UNION ALL
    
    SELECT 
        ws.item_sk,
        SUM(ws.ws_quantity) + cte.total_quantity,
        SUM(ws.ws_net_paid_inc_tax) + cte.total_revenue,
        COUNT(DISTINCT ws.ws_order_number) + cte.total_orders,
        cte.level + 1
    FROM web_sales ws
    JOIN SalesCTE cte ON ws.ws_item_sk = cte.ws_item_sk
    WHERE cte.level < 5
    GROUP BY ws.item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_gender
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        si.i_item_id,
        si.i_item_desc,
        COALESCE(SUM(su.total_quantity), 0) AS total_sales_quantity,
        COALESCE(SUM(su.total_revenue), 0) AS total_sales_revenue
    FROM item si
    LEFT JOIN SalesCTE su ON si.i_item_sk = su.ws_item_sk
    GROUP BY si.i_item_id, si.i_item_desc
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.gender,
    ss.total_sales_quantity,
    ss.total_sales_revenue,
    CASE 
        WHEN ss.total_sales_revenue > 5000 THEN 'High Value Customer'
        WHEN ss.total_sales_revenue BETWEEN 1000 AND 5000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_classification,
    CASE 
        WHEN ci.cd_credit_rating IS NULL THEN 'No Rating'
        ELSE ci.cd_credit_rating
    END AS credit_rating_status
FROM CustomerInfo ci
LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.i_item_sk
WHERE ci.rank_by_gender <= 10
ORDER BY ci.gender, ss.total_sales_revenue DESC
FETCH FIRST 100 ROWS ONLY;
