
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_paid) AS avg_order_value,
        MAX(ws.sales_price) AS max_item_price,
        MIN(ws.sales_price) AS min_item_price,
        COUNT(CASE WHEN ws.net_paid IS NULL THEN 1 END) AS null_paid_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ship_date_sk > 0
        AND (ws.list_price BETWEEN 10.00 AND 500.00 OR ws.ext_discount_amt IS NULL)
    GROUP BY 
        ws.web_site_id
),
returns_data AS (
    SELECT 
        wr.web_site_id,
        COUNT(wr.return_quantity) AS total_returns,
        SUM(wr.return_amt) AS total_return_value,
        COUNT(DISTINCT wr.order_number) AS total_returned_orders
    FROM 
        web_returns wr
    GROUP BY 
        wr.web_site_id
),
combined_data AS (
    SELECT 
        sd.web_site_id,
        sd.total_sales,
        sd.total_orders,
        sd.avg_order_value,
        sd.max_item_price,
        sd.min_item_price,
        rd.total_returns,
        rd.total_return_value,
        rd.total_returned_orders
    FROM 
        sales_data sd
    FULL OUTER JOIN 
        returns_data rd ON sd.web_site_id = rd.web_site_id
),
ranked_data AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        avg_order_value,
        max_item_price,
        min_item_price,
        total_returns,
        total_return_value,
        total_returned_orders,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY total_return_value ASC) AS return_rank
    FROM 
        combined_data
)
SELECT 
    web_site_id,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(avg_order_value, 0) AS avg_order_value,
    COALESCE(max_item_price, 0.00) AS max_item_price,
    COALESCE(min_item_price, 0.00) AS min_item_price,
    COALESCE(total_returns, 0) AS total_returns,
    COALESCE(total_return_value, 0.00) AS total_return_value,
    COALESCE(total_returned_orders, 0) AS total_returned_orders,
    CASE 
        WHEN sales_rank IS NULL THEN 'Rank not available'
        ELSE CAST(sales_rank AS VARCHAR)
    END AS sales_rank_info,
    CASE 
        WHEN return_rank IS NULL THEN 'Rank not available'
        ELSE CAST(return_rank AS VARCHAR)
    END AS return_rank_info
FROM 
    ranked_data
WHERE 
    (total_sales > 10000 OR total_returns < 5)
    AND (sales_rank < 5 OR (total_orders >= 100 AND total_returned_orders IS NOT NULL))
ORDER BY 
    total_sales DESC, total_orders ASC
LIMIT 10;
