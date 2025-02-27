
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS customer_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk,
        ws_item_sk
),
top_customer_sales AS (
    SELECT 
        sd.ws_bill_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sd.total_quantity,
        sd.total_profit,
        RANK() OVER (ORDER BY sd.total_profit DESC) AS profit_rank
    FROM 
        sales_data sd
    JOIN 
        customer c ON sd.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        sd.customer_rank <= 5
),
most_popular_items AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS item_sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    ORDER BY 
        item_sales_count DESC
    LIMIT 10
)
SELECT 
    tcs.ws_bill_customer_sk,
    tcs.c_first_name,
    tcs.c_last_name,
    tcs.total_quantity,
    tcs.total_profit,
    mpi.ws_item_sk,
    mpi.item_sales_count
FROM 
    top_customer_sales tcs
LEFT JOIN 
    most_popular_items mpi ON tcs.ws_item_sk = mpi.ws_item_sk
WHERE 
    tcs.profit_rank <= 5 OR mpi.item_sales_count IS NOT NULL
ORDER BY 
    tcs.total_profit DESC,
    tcs.c_first_name ASC;
