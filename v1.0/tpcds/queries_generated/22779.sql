
WITH Ranked_Returns AS (
    SELECT 
        cr_returning_customer_sk,
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_quantity) DESC) AS rnk
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk, cr_item_sk
),
Top_Returns AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        wrapped.sum_of_returns,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        ROW_NUMBER() OVER (ORDER BY wrapped.sum_of_returns DESC) AS row_num
    FROM 
        customer
    LEFT JOIN 
        customer_demographics cd ON customer.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            rr.cr_returning_customer_sk,
            SUM(rr.total_returned) AS sum_of_returns
        FROM 
            Ranked_Returns rr
        WHERE 
            rr.rnk = 1
        GROUP BY 
            rr.cr_returning_customer_sk
    ) wrapped ON customer.c_customer_sk = wrapped.cr_returning_customer_sk
),
Sales_Info AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_id
),
Combined_Info AS (
    SELECT 
        tr.c_customer_id,
        tr.c_first_name,
        tr.c_last_name,
        COALESCE(si.total_net_profit, 0) AS total_net_profit,
        COALESCE(si.total_quantity, 0) AS total_quantity,
        COALESCE(si.total_orders, 0) AS total_orders
    FROM 
        Top_Returns tr
    LEFT JOIN 
        Sales_Info si ON tr.row_num <= 10
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.total_net_profit,
    ci.total_quantity,
    ci.total_orders,
    CASE 
        WHEN ci.total_orders = 0 THEN 'No Orders'
        ELSE 'Active Customer'
    END AS customer_status,
    ROUND(ci.total_net_profit / NULLIF(ci.total_orders, 0), 2) AS avg_profit_per_order
FROM 
    Combined_Info ci
WHERE 
    ci.total_net_profit > 1000
ORDER BY 
    ci.total_net_profit DESC
LIMIT 5;
