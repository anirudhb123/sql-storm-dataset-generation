
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_ship_date_sk,
        ws_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
customer_summary AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Mr. ' || c_first_name
            WHEN cd_gender = 'F' THEN 'Ms. ' || c_first_name
            ELSE c_first_name 
        END AS full_name,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c_customer_sk, c_first_name, c_last_name, cd_gender
),
sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_net_paid > 0
    GROUP BY 
        ws_item_sk
),
item_profit AS (
    SELECT 
        i_item_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        i_item_sk
),
final_report AS (
    SELECT 
        cs.full_name,
        COALESCE(ss.total_net_paid, 0) AS total_net_paid,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        ip.total_net_profit,
        rs.profit_rank
    FROM 
        customer_summary cs
    LEFT JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_item_sk
    LEFT JOIN 
        item_profit ip ON ss.ws_item_sk = ip.i_item_sk
    LEFT JOIN 
        ranked_sales rs ON ss.ws_item_sk = rs.ws_item_sk
    WHERE 
        ip.total_net_profit IS NOT NULL
    ORDER BY 
        total_net_paid DESC, total_quantity ASC
)
SELECT 
    DISTINCT f.* 
FROM 
    final_report f
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM final_report f2 
        WHERE f2.total_net_paid < f.total_net_paid 
        AND f2.profit_rank IS NOT NULL
    )
    OR f.profit_rank IS NULL
ORDER BY 
    f.total_net_paid DESC, 
    f.total_quantity DESC;
