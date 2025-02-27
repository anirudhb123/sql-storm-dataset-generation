
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
high_performance_items AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sd.total_sales,
        sd.order_count
    FROM 
        sales_data sd
    JOIN 
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE 
        sd.rank <= 10
),
customer_return_analysis AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT wr_order_number) AS total_web_returns,
        SUM(wr_return_amt) AS total_web_return_amt
    FROM 
        web_returns wr
    JOIN 
        customer c ON wr_returning_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    DISTINCT hpi.i_item_id,
    hpi.i_item_desc,
    hpi.total_sales,
    hpi.order_count,
    cra.c_customer_id,
    COALESCE(cra.total_web_returns, 0) AS total_returns,
    COALESCE(cra.total_web_return_amt, 0) AS total_return_amount,
    -- Using case statement to denote high value customers with defined criteria
    CASE 
        WHEN COALESCE(cra.total_web_return_amt, 0) > 500 THEN 'High Value'
        ELSE 'Standard'
    END AS customer_value_category
FROM 
    high_performance_items hpi
LEFT JOIN 
    customer_return_analysis cra ON hpi.order_count > 5
ORDER BY 
    hpi.total_sales DESC, 
    customer_value_category;
