
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING SUM(ws_quantity) > 10
    
    UNION ALL
    
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.quantity) AS total_quantity,
        SUM(ss.ext_sales_price) AS total_sales
    FROM
        store_sales ss
    JOIN sales_summary ssu ON ss.sold_date_sk = ssu.ws_sold_date_sk AND ss.item_sk = ssu.ws_item_sk
    GROUP BY 
        ss.sold_date_sk, ss.item_sk
),
highest_sales AS (
    SELECT 
        ws_item_sk,
        MAX(total_sales) AS max_sales
    FROM 
        sales_summary
    GROUP BY 
        ws_item_sk
),
customer_returns AS (
    SELECT 
        wr_refunded_customer_sk AS customer_sk,
        COUNT(DISTINCT wr_return_number) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM
        web_returns
    GROUP BY 
        wr_refunded_customer_sk
),
final_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(hd.total_returns, 0) AS total_returns,
        COALESCE(hd.total_return_amount, 0) AS total_return_amount,
        hs.max_sales
    FROM 
        customer c
    LEFT JOIN customer_returns hd ON c.c_customer_sk = hd.customer_sk
    JOIN highest_sales hs ON hs.ws_item_sk IN (
        SELECT 
            web_sales.ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_quantity > 5
    )
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_returns,
    f.total_return_amount,
    f.max_sales,
    CASE 
        WHEN f.total_returns > 0 THEN 'Frequent Returner' 
        ELSE 'Rare Returner' 
    END AS returner_type,
    DENSE_RANK() OVER (PARTITION BY f.max_sales ORDER BY f.total_return_amount DESC) AS sales_rank
FROM 
    final_summary f
WHERE 
    f.max_sales > (SELECT AVG(max_sales) FROM highest_sales);
