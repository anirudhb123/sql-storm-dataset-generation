
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_net_profit) AS total_profit,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_net_profit) DESC) AS rn
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND cs_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs_item_sk
),
sales_analysis AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_profit,
        ss.total_orders,
        i.i_product_name,
        ROW_NUMBER() OVER (ORDER BY ss.total_profit DESC) AS profit_rank,
        COALESCE(i.i_current_price, 0) AS current_price,
        CASE 
            WHEN i.i_current_price IS NOT NULL AND ss.total_profit > 0 
            THEN (ss.total_profit / i.i_current_price) * 100 
            ELSE 0 
        END AS profit_margin_percentage,
        COUNT(DISTINCT wr_return_number) AS total_returns
    FROM 
        sales_summary ss
    LEFT JOIN 
        item i ON ss.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        web_returns wr ON wr.wr_item_sk = i.i_item_sk
    GROUP BY 
        ss.ws_item_sk, ss.total_profit, ss.total_orders, i.i_product_name, i.i_current_price
)
SELECT 
    sa.i_product_name,
    sa.total_profit,
    sa.total_orders,
    sa.profit_margin_percentage,
    sa.total_returns,
    CASE 
        WHEN sa.profit_margin_percentage > 50 THEN 'High'
        WHEN sa.profit_margin_percentage BETWEEN 25 AND 50 THEN 'Medium'
        ELSE 'Low'
    END AS profitability_category
FROM 
    sales_analysis sa
WHERE 
    sa.total_orders > 0
ORDER BY 
    sa.total_profit DESC
LIMIT 10;
