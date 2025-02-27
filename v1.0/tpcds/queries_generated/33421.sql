
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        1 AS level
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_order_number
    UNION ALL
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        sh.total_quantity + SUM(ws.ws_quantity) AS total_quantity,
        sh.total_profit + SUM(ws.ws_net_profit) AS total_profit,
        level + 1
    FROM 
        web_sales ws
    JOIN 
        sales_hierarchy sh ON ws.ws_item_sk = sh.ws_item_sk 
    WHERE 
        ws.ws_order_number > sh.ws_order_number
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number, sh.total_quantity, sh.total_profit, level
),
item_summary AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(s.total_quantity), 0) AS total_sales_quantity,
        COALESCE(SUM(s.total_profit), 0) AS total_sales_profit,
        AVG(i.i_current_price) AS avg_item_price
    FROM 
        item i
    LEFT JOIN 
        sales_hierarchy s ON i.i_item_sk = s.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    i.total_sales_quantity,
    i.total_sales_profit,
    i.avg_item_price,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    cd.total_estimate
FROM 
    item_summary i
LEFT JOIN 
    customer_demographics cd ON i.total_sales_quantity > cd.total_estimate
WHERE 
    i.total_sales_quantity > 100
ORDER BY 
    i.total_sales_profit DESC,
    cd.customer_count ASC
FETCH FIRST 100 ROWS ONLY;
