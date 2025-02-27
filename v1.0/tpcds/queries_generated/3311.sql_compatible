
WITH sales_summary AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year >= 2020
    GROUP BY 
        d.d_year
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cs.full_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.cd_credit_rating,
    ss.d_year,
    ss.total_net_profit,
    ss.total_quantity,
    ss.total_orders,
    CASE 
        WHEN ss.total_net_profit IS NULL THEN 'No Sales'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = (
        SELECT 
            ws.ws_bill_customer_sk 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_bill_customer_sk = cs.c_customer_sk 
        ORDER BY 
            ws.ws_sold_date_sk DESC 
        FETCH FIRST 1 ROW ONLY
    )
WHERE 
    (cs.cd_gender = 'F' AND cs.cd_purchase_estimate > 1000)
    OR (cs.cd_gender = 'M' AND cs.cd_purchase_estimate IS NOT NULL AND cs.cd_credit_rating = 'Excellent')
ORDER BY 
    ss.total_net_profit DESC NULLS LAST,
    cs.full_name;
