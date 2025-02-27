
WITH RECURSIVE sales_performance AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        ws_item_sk,
        SUM(total_sales) AS cumulative_sales
    FROM 
        sales_performance
    WHERE 
        sales_rank <= 10
    GROUP BY 
        ws_item_sk
),
average_sales AS (
    SELECT 
        item.i_item_sk,
        item.i_item_desc,
        COALESCE(AVG(ts.cumulative_sales), 0) AS avg_sales
    FROM 
        item
    LEFT JOIN 
        top_sales ts ON item.i_item_sk = ts.ws_item_sk
    GROUP BY 
        item.i_item_sk, item.i_item_desc
),
sales_analysis AS (
    SELECT 
        id.i_item_id,
        id.i_brand,
        id.i_category,
        avg_sales,
        CASE 
            WHEN avg_sales > 100 THEN 'High Sales'
            WHEN avg_sales >= 50 AND avg_sales <= 100 THEN 'Moderate Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM 
        average_sales avg_sales
    JOIN 
        item id ON avg_sales.i_item_sk = id.i_item_sk
)
SELECT 
    ca.ca_state,
    COUNT(DISTINCT sa.i_item_id) AS items_sold,
    SUM(sa.avg_sales) AS total_avg_sales,
    MAX(sa.avg_sales) AS max_avg_sales,
    MIN(sa.avg_sales) AS min_avg_sales,
    CASE 
        WHEN SUM(sa.avg_sales) < 500 THEN 'Low Performance'
        WHEN SUM(sa.avg_sales) BETWEEN 500 AND 1000 THEN 'Average Performance'
        ELSE 'High Performance'
    END AS performance_category
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    sales_analysis sa ON c.c_customer_sk = sa.i_item_id
GROUP BY 
    ca.ca_state
ORDER BY 
    ca.ca_state;
