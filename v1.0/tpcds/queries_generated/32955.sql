
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    HAVING 
        SUM(ws_net_paid) > 1000
),
daily_performance AS (
    SELECT 
        d.d_date,
        COALESCE(SUM(sd.total_quantity), 0) AS total_quantity,
        COALESCE(SUM(sd.total_sales), 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY d.d_dow ORDER BY d.d_date) AS daily_rank,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(sd.total_sales), 0) DESC) AS sales_rank
    FROM 
        date_dim d
    LEFT JOIN 
        sales_data sd ON d.d_date_sk = sd.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
),
top_days AS (
    SELECT 
        d.d_date,
        d.daily_rank,
        d.sales_rank,
        d.total_quantity,
        d.total_sales
    FROM 
        daily_performance d
    WHERE 
        d.sales_rank <= 5
)
SELECT 
    d.d_date,
    d.total_quantity,
    d.total_sales,
    CASE 
        WHEN d.total_sales IS NULL THEN 'No Sales'
        ELSE CONCAT('$', CAST(d.total_sales AS VARCHAR))
    END AS formatted_sales,
    COALESCE(address.ca_city, 'Unknown City') AS city,
    COALESCE(address.ca_state, 'Unknown State') AS state
FROM 
    top_days d
LEFT JOIN 
    customer_address address ON d.sales_rank = address.ca_address_sk
OUTER APPLY (
    SELECT 
        MAX(wr_returned_date_sk) AS latest_return_date
    FROM 
        web_returns
    WHERE 
        wr_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk = d.ws_sold_date_sk)
) AS return_info
WHERE 
    return_info.latest_return_date IS NULL OR d.total_sales > 5000 
ORDER BY 
    d.d_date DESC;
