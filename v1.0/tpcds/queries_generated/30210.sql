
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_segment AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender
),
high_performance_items AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        item
    JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    GROUP BY 
        item.i_item_sk, item.i_product_name
    HAVING 
        total_quantity > 1000
),
return_statistics AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)

SELECT 
    item.i_item_sk,
    item.i_product_name,
    sales.total_sales_price,
    sales.total_quantity,
    customer_seg.total_customers,
    customer_seg.avg_purchase_estimate,
    return_stats.total_returns,
    return_stats.total_returned_amount
FROM 
    high_performance_items sales
LEFT JOIN 
    customer_segment customer_seg ON sales.total_quantity > 500
LEFT JOIN 
    return_statistics return_stats ON sales.i_item_sk = return_stats.sr_item_sk
WHERE 
    customer_seg.total_customers IS NOT NULL
    AND sales.total_profit > 5000
ORDER BY 
    sales.total_profit DESC
LIMIT 10;
