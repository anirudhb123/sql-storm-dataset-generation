
WITH ranked_sales AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
high_value_customers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        cd_credit_rating,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_purchase_estimate > 1000
        AND cd_credit_rating IS NOT NULL
),
high_sales_items AS (
    SELECT 
        item.i_item_sk, 
        item.i_item_id, 
        item.i_product_name,
        COALESCE(SUM(ws_net_profit), 0) AS net_profit
    FROM 
        item
    LEFT JOIN 
        web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_id, item.i_product_name
    HAVING 
        net_profit > 5000
),
temp_ranked AS (
    SELECT
        ws_bill_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY total_sales_price DESC) AS rank,
        SUM(total_sales_price) AS total_sales 
    FROM 
        ranked_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    COALESCE(s.total_sales, 0) AS total_sales, 
    i.i_product_name AS item
FROM 
    high_value_customers c
LEFT JOIN 
    temp_ranked s ON c.c_customer_sk = s.ws_bill_customer_sk AND s.rank <= 3
LEFT JOIN 
    high_sales_items i ON i.i_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_customer_sk = c.c_customer_sk 
        GROUP BY 
            ws_item_sk 
        ORDER BY 
            SUM(ws_sales_price) DESC 
        LIMIT 1 
    )
WHERE 
    c.cd_credit_rating IN ('A', 'B')
ORDER BY 
    c.c_last_name, 
    c.c_first_name;
