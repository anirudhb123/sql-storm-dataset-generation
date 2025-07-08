
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
sales_summary AS (
    SELECT 
        i.i_item_id, 
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_net_profit
    FROM 
        item AS i
    LEFT JOIN 
        web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
customer_avg AS (
    SELECT 
        c.c_customer_id,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        cd.cd_marital_status IN ('M', 'S')
    GROUP BY 
        c.c_customer_id
),
item_sales AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ss.ss_quantity), 0) AS store_quantity,
        MAX(ss.ss_net_profit) AS max_store_net_profit
    FROM 
        item AS i
    LEFT JOIN 
        store_sales AS ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    iss.i_item_id,
    iss.store_quantity,
    iss.max_store_net_profit,
    rws.rank,
    CASE 
        WHEN css.total_quantity > 0 THEN 'Sales Exist'
        ELSE 'No Sales' 
    END AS sales_status,
    ca.avg_purchase_estimate AS avg_estimate
FROM 
    item_sales AS iss
JOIN 
    ranked_sales AS rws ON iss.i_item_id = (SELECT i.i_item_id FROM item i WHERE i.i_item_sk = rws.ws_item_sk)
LEFT JOIN 
    sales_summary AS css ON iss.i_item_id = css.i_item_id
LEFT JOIN 
    customer_avg AS ca ON ca.customer_count = (SELECT COUNT(*) FROM customer)
WHERE 
    iss.store_quantity + COALESCE(css.total_quantity, 0) BETWEEN 10 AND 100
    OR iss.max_store_net_profit IS NULL
ORDER BY 
    COALESCE(iss.store_quantity, 0) DESC, 
    rws.rank ASC;
