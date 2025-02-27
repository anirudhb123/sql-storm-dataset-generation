
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
    UNION ALL
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity_sold,
        SUM(s.ss_net_profit) AS total_net_profit
    FROM 
        store_sales s
    JOIN 
        sales_cte sc ON s.ss_item_sk = sc.ws_item_sk
    GROUP BY 
        s.ss_sold_date_sk, 
        s.ss_item_sk
),
sales_summary AS (
    SELECT 
        cd.cd_gender,
        ca.ca_state,
        SUM(s.total_quantity_sold) AS quantity_sold,
        SUM(s.total_net_profit) AS net_profit
    FROM 
        sales_cte s
    JOIN 
        customer c ON c.c_customer_sk = s.ws_item_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IS NOT NULL
    GROUP BY 
        cd.cd_gender, 
        ca.ca_state
)
SELECT 
    s.cd_gender,
    s.ca_state,
    COALESCE(s.quantity_sold, 0) AS quantity_sold,
    COALESCE(s.net_profit, 0) AS net_profit,
    RANK() OVER (PARTITION BY s.ca_state ORDER BY s.net_profit DESC) AS rank_by_profit
FROM 
    sales_summary s
FULL OUTER JOIN 
    customer_demographics cd ON s.cd_gender = cd.cd_gender
WHERE 
    (s.quantity_sold IS NOT NULL OR s.net_profit IS NOT NULL)
ORDER BY 
    s.ca_state, 
    rank_by_profit;
