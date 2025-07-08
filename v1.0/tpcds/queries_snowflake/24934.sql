
WITH yearly_sales AS (
    SELECT 
        d.d_year, 
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
customer_segments AS (
    SELECT 
        cd.cd_gender,
        hd.hd_buy_potential,
        COUNT(DISTINCT c.c_customer_sk) AS segment_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    GROUP BY 
        cd.cd_gender, hd.hd_buy_potential
),
inventory_details AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        CASE 
            WHEN SUM(inv.inv_quantity_on_hand) IS NULL THEN 'Out of Stock'
            WHEN SUM(inv.inv_quantity_on_hand) = 0 THEN 'No Stock Available'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        item i
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    y.d_year,
    y.total_profit,
    y.total_orders,
    cs.cd_gender,
    cs.hd_buy_potential,
    cs.segment_count,
    id.total_quantity,
    id.stock_status
FROM 
    yearly_sales y
JOIN 
    customer_segments cs ON y.d_year = (SELECT MAX(y2.d_year) FROM yearly_sales y2 WHERE y2.total_profit > y.total_profit)
LEFT JOIN 
    inventory_details id ON id.stock_status = 'In Stock' AND id.total_quantity > 100
WHERE 
    y.rank_profit <= 10 
ORDER BY 
    y.d_year DESC, y.total_profit DESC;
