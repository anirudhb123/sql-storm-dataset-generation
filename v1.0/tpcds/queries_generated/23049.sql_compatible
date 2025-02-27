
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws_item_sk
),
high_profit_items AS (
    SELECT 
        rs.ws_item_sk, 
        rs.total_net_profit,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(NULLIF(hd.hd_buy_potential, 'Low'), 'Unsure') AS buying_potential,
        DENSE_RANK() OVER (ORDER BY rs.total_net_profit DESC) AS item_rank
    FROM 
        ranked_sales rs
    JOIN 
        item i ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = (
            SELECT 
                hd_demo_sk 
            FROM 
                customer 
            WHERE 
                c_customer_sk = (
                    SELECT ws_bill_customer_sk 
                    FROM web_sales 
                    WHERE ws_item_sk = rs.ws_item_sk 
                    LIMIT 1
                )
        )
    WHERE 
        rs.profit_rank <= 10
),
most_popular_items AS (
    SELECT 
        cs.cs_item_sk,
        COUNT(*) AS order_count
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_item_sk
    HAVING 
        COUNT(*) > (
            SELECT AVG(order_count) 
            FROM (
                SELECT COUNT(*) AS order_count 
                FROM catalog_sales 
                GROUP BY cs_item_sk
            ) avg_counts
        )
),
final_selection AS (
    SELECT 
        hpi.ws_item_sk, 
        hpi.total_net_profit, 
        hpi.i_item_desc, 
        hpi.i_current_price, 
        mpi.order_count
    FROM 
        high_profit_items hpi
    JOIN 
        most_popular_items mpi ON hpi.ws_item_sk = mpi.cs_item_sk
)
SELECT 
    i_item_desc AS item_desc, 
    i_current_price AS current_price, 
    total_net_profit, 
    order_count,
    CASE 
        WHEN total_net_profit IS NULL THEN 'No Profit'
        WHEN total_net_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    final_selection
WHERE 
    (i_item_desc LIKE '%Gadget%' OR i_item_desc IS NOT NULL) 
    AND order_count > 5
ORDER BY 
    total_net_profit DESC NULLS LAST;
