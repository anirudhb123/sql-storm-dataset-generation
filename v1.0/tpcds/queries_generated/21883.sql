
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
total_sales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_profit) AS total_profit
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_net_profit IS NOT NULL
    GROUP BY 
        cs.cs_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status
        END AS marital_status,
        COALESCE(hd.hd_buy_potential, 'Low') AS buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
return_stats AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(DISTINCT cr.cr_order_number) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amt
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.marital_status,
    ci.buy_potential,
    COALESCE(ts.total_profit, 0) AS total_catalog_profit,
    COALESCE(SUM(rs.ws_quantity), 0) AS total_web_sales_quantity,
    COALESCE(rs.rn, 0) AS top_sales_rank,
    COALESCE(rs.ws_net_profit, 0) AS top_web_net_profit,
    COALESCE(rs.ws_item_sk, 'N/A') AS top_selling_item,
    COALESCE(rs.ws_order_number, 'N/A') AS top_order_number,
    COALESCE(rs.ws_quantity, 0) AS quantity_of_top_item_sold,
    COALESCE(rs.ws_net_profit, 0) - COALESCE(rs.return_count, 0) AS net_profit_after_returns,
    COALESCE(rs.return_count, 0) AS total_item_returns
FROM 
    customer_info ci
LEFT JOIN 
    total_sales ts ON ci.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL LIMIT 1)
LEFT JOIN 
    ranked_sales rs ON ci.buy_potential = 'High' AND rs.rn = 1
LEFT JOIN 
    return_stats ret ON ret.cr_item_sk = rs.ws_item_sk
WHERE 
    ci.c_customer_id IS NOT NULL
GROUP BY 
    ci.c_customer_id, ci.cd_gender, ci.marital_status, ci.buy_potential, ts.total_profit, rs.rn, rs.ws_item_sk, rs.ws_order_number
HAVING 
    SUM(COALESCE(rs.ws_quantity, 0)) > 0 OR total_catalog_profit > 5000
ORDER BY 
    net_profit_after_returns DESC
LIMIT 100;
