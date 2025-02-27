
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity + COALESCE((SELECT SUM(ws_quantity) 
                                    FROM web_sales 
                                    WHERE ws_sold_date_sk < sd.ws_sold_date_sk 
                                    AND ws_item_sk = sd.ws_item_sk), 0) AS total_quantity,
        total_net_profit + COALESCE((SELECT SUM(ws_net_profit) 
                                       FROM web_sales 
                                       WHERE ws_sold_date_sk < sd.ws_sold_date_sk 
                                       AND ws_item_sk = sd.ws_item_sk), 0) AS total_net_profit
    FROM 
        sales_data sd
    WHERE 
        sd.total_quantity > 0
),
address_info AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_state
),
sales_summary AS (
    SELECT 
        d_year,
        SUM(total_net_profit) AS total_profit,
        AVG(total_quantity) AS avg_quantity
    FROM 
        sales_data 
    JOIN date_dim d ON sales_data.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d_year
),
final_summary AS (
    SELECT 
        asi.ca_state,
        asi.customer_count,
        asi.avg_purchase_estimate,
        ss.total_profit,
        ss.avg_quantity
    FROM 
        address_info asi
    LEFT JOIN sales_summary ss ON asi.customer_count > 100 AND ss.total_profit IS NOT NULL
)
SELECT 
    fs.ca_state,
    COALESCE(fs.customer_count, 0) AS customer_count,
    COALESCE(fs.avg_purchase_estimate, 0) AS avg_purchase_estimate,
    COALESCE(fs.total_profit, 0) AS total_profit,
    COALESCE(fs.avg_quantity, 0) AS avg_quantity,
    CASE 
        WHEN fs.total_profit > 10000 THEN 'High Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    final_summary fs
ORDER BY 
    performance_category DESC, fs.customer_count DESC;
