
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk + 1, 
        ws_item_sk, 
        total_quantity, 
        total_profit
    FROM 
        sales_data
    WHERE 
        ws_sold_date_sk < (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
customer_segment AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE 
        cd_marital_status = 'M' AND
        (cd_gender = 'F' OR cd_gender = 'M')
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
top_items AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_product_name,
        RANK() OVER (ORDER BY SUM(total_profit) DESC) AS item_rank
    FROM 
        sales_data
    JOIN 
        item ON sales_data.ws_item_sk = item.i_item_sk
    GROUP BY 
        i_item_sk, i_item_id, i_product_name
)
SELECT 
    customer_segment.cd_gender,
    customer_segment.cd_marital_status,
    COUNT(DISTINCT sales_data.ws_item_sk) AS items_sold,
    SUM(sales_data.total_profit) AS total_profit,
    STRING_AGG(DISTINCT CONCAT(top_items.i_product_name, ' (Item ID: ', top_items.i_item_id, ')'), '; ') AS top_selling_items
FROM 
    customer_segment
LEFT JOIN 
    sales_data ON customer_segment.customer_count > 0
LEFT JOIN 
    top_items ON sales_data.ws_item_sk = top_items.i_item_sk AND top_items.item_rank <= 5
GROUP BY 
    customer_segment.cd_gender, customer_segment.cd_marital_status
HAVING 
    SUM(sales_data.total_profit) IS NOT NULL
ORDER BY 
    total_profit DESC;
