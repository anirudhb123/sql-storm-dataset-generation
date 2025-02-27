
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status = 'M')
    GROUP BY 
        ws.ws_order_number, ws.ws_web_site_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        CASE 
            WHEN cd.cd_dep_count > 2 THEN 'Family'
            WHEN cd.cd_dep_count = 1 THEN 'Single'
            ELSE 'Group'
        END AS customer_type
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
store_return_summary AS (
    SELECT 
        sr_store_sk,
        SUM(sr_returned_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    s.s_store_name,
    s.s_city,
    s.s_state,
    SUM(r.total_net_profit) AS total_profit,
    COALESCE(r.rank_profit, 0) AS web_sales_rank,
    cu.c_first_name,
    cu.c_last_name,
    cu.customer_type,
    rs.total_returns,
    rs.unique_returns
FROM 
    store s
LEFT JOIN 
    ranked_sales r ON r.ws_order_number IN (
        SELECT DISTINCT ws_order_number 
        FROM web_sales 
        WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    )
LEFT JOIN 
    customer_info cu ON cu.c_customer_sk = r.ws_bill_customer_sk
LEFT JOIN 
    store_return_summary rs ON rs.sr_store_sk = s.s_store_sk
WHERE 
    s.s_state IN ('CA', 'NY') 
    AND (rs.total_returns IS NULL OR rs.total_returns < 100)
GROUP BY 
    s.s_store_name, s.s_city, s.s_state, cu.c_first_name, cu.c_last_name, cu.customer_type, rs.total_returns, rs.unique_returns
HAVING 
    SUM(r.total_net_profit) > 1000 OR COUNT(r.rank_profit) > 3
ORDER BY 
    total_profit DESC, s.s_store_name ASC;
