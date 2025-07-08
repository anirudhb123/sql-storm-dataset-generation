
WITH sales_data AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_sold,
           SUM(ws_sales_price) AS total_revenue,
           d.d_year
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2020
    GROUP BY ws_item_sk, d.d_year

    UNION ALL

    SELECT sd.ws_item_sk, 
           sd.total_sold + additional_sales.total_sold AS total_sold,
           sd.total_revenue + additional_sales.total_revenue AS total_revenue,
           additional_sales.d_year
    FROM sales_data sd
    JOIN (
        SELECT ws_item_sk, 
               SUM(ws_quantity) AS total_sold,
               SUM(ws_sales_price) AS total_revenue,
               d.d_year
        FROM web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        WHERE d.d_year = sd.d_year + 1
        GROUP BY ws_item_sk, d.d_year
    ) additional_sales ON sd.ws_item_sk = additional_sales.ws_item_sk
),
sales_summary AS (
    SELECT item.i_item_id,
           item.i_product_name,
           COALESCE(sd.total_sold, 0) AS total_sold,
           COALESCE(sd.total_revenue, 0) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY item.i_item_id ORDER BY sd.d_year DESC) AS rank
    FROM item
    LEFT JOIN sales_data sd ON item.i_item_sk = sd.ws_item_sk
    WHERE item.i_current_price > 0 
    AND (item.i_brand LIKE 'Brand%' OR item.i_category LIKE 'Category%')
)
SELECT ss.i_item_id,
       ss.i_product_name,
       ss.total_sold,
       ss.total_revenue,
       ss.rank
FROM sales_summary ss
WHERE ss.rank = 1
AND ss.total_revenue > (SELECT AVG(ss2.total_revenue) FROM sales_summary ss2)
ORDER BY ss.total_revenue DESC
LIMIT 10;
