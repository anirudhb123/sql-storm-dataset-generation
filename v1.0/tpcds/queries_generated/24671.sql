
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) as rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
),
customer_ranked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        DENSE_RANK() OVER (ORDER BY c.c_birth_year DESC) as birth_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        COUNT(*) AS total_inventory,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS available_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
return_summary AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_returned_amount,
        AVG(sr.sr_net_loss) AS average_net_loss
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
combined_data AS (
    SELECT 
        cs.ws_item_sk,
        SUM(cs.ws_quantity) AS total_sold,
        SUM(cs.ws_net_profit) AS total_profit,
        COALESCE(SUM(rs.total_returns), 0) AS total_returns,
        cs.total_inventory,
        cs.available_quantity
    FROM 
        sales_data cs
    LEFT JOIN 
        inventory_status cs ON cs.ws_item_sk = is.inv_item_sk
    LEFT JOIN 
        return_summary rs ON cs.ws_item_sk = rs.sr_item_sk
    WHERE 
        (cs.total_inventory IS NOT NULL AND cs.available_quantity > 0)
    GROUP BY 
        cs.ws_item_sk
)
SELECT 
    cr.c_first_name,
    SUM(cd.total_sold) AS total_sales,
    SUM(cd.total_profit) AS total_profit,
    SUM(cd.total_returns) AS total_returns
FROM 
    combined_data cd
JOIN 
    customer_ranked cr ON cr.c_customer_sk = cd.ws_item_sk
WHERE 
    cr.birth_rank <= 5 
GROUP BY 
    cr.c_first_name 
HAVING 
    SUM(cd.total_profit) > 1000 OR 
    (SUM(cd.total_returns) IS NULL AND SUM(cd.total_sold) > 0)
ORDER BY 
    total_sales DESC
LIMIT 10;
