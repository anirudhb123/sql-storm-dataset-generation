
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND i.i_current_price > 20 
    GROUP BY 
        ws.ws_item_sk
),
high_value_items AS (
    SELECT 
        ir.i_item_id,
        ir.total_orders,
        ir.total_profit
    FROM 
        ranked_sales ir
    WHERE 
        ir.profit_rank = 1
),
item_details AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        ib.ib_income_band_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown Income'
            ELSE CONCAT('Income Band: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_band_description
    FROM 
        item i
    LEFT JOIN 
        household_demographics h ON i.i_item_sk = h.hd_demo_sk
    LEFT JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    hi.i_item_id,
    hi.total_orders,
    hi.total_profit,
    id.i_item_desc,
    id.income_band_description
FROM 
    high_value_items hi
JOIN 
    item_details id ON hi.i_item_id = id.i_item_id
WHERE 
    hi.total_profit > (SELECT AVG(total_profit) FROM ranked_sales)
ORDER BY 
    hi.total_profit DESC
LIMIT 10;
