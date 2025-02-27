
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        total_quantity + ss.total_quantity, 
        total_profit + ss.total_profit
    FROM 
        sales_summary ss
    JOIN 
        web_sales ws ON ss.ws_item_sk = ws.ws_item_sk
    WHERE 
        ss.ws_sold_date_sk < ws.sold_date_sk
),
ranked_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.ws_sold_date_sk, 
        SUM(ss.total_profit) OVER (PARTITION BY ss.ws_item_sk ORDER BY ss.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        RANK() OVER (PARTITION BY ss.ws_item_sk ORDER BY SUM(ss.total_profit) DESC) AS rank_profit
    FROM 
        sales_summary ss
)
SELECT 
    r.ws_item_sk,
    r.ws_sold_date_sk,
    r.cumulative_profit,
    ra.ca_city,
    case 
        when r.cumulative_profit IS NULL then 'No Sales' 
        else 'Sales Present' 
    end as sales_status
FROM 
    ranked_sales r
LEFT JOIN 
    customer_address ra ON ra.ca_address_sk = (
        SELECT 
            c.c_current_addr_sk 
        FROM 
            customer c 
        WHERE 
            c.c_customer_sk = (SELECT 
                                   DISTINCT ws_bill_customer_sk 
                               FROM 
                                   web_sales 
                               WHERE 
                                   ws_item_sk = r.ws_item_sk 
                               LIMIT 1) 
    )
WHERE 
    r.rank_profit <= 10
ORDER BY 
    r.cumulative_profit DESC;
