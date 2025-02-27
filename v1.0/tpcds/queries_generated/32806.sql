
WITH RECURSIVE item_hierarchy AS (
    SELECT 
        i_item_sk,
        i_item_id,
        i_product_name,
        i_category
    FROM 
        item
    WHERE 
        i_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
    
    UNION ALL

    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category
    FROM 
        item_hierarchy ih
    JOIN 
        item i ON ih.i_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date < CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
sales_data AS (
    SELECT 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ws_item_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459585 AND 2459630
    GROUP BY 
        ws_item_sk
),
customer_stats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_credit_rating IN ('Excellent', 'Good')
    GROUP BY 
        cd_gender
),
ranked_sales AS (
    SELECT 
        ih.i_product_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY COALESCE(sd.total_sales, 0) DESC) AS sales_rank
    FROM 
        item_hierarchy ih
    LEFT JOIN 
        sales_data sd ON ih.i_item_sk = sd.ws_item_sk
)
SELECT 
    r.i_product_name,
    r.total_sales,
    cs.cd_gender,
    cs.customer_count,
    cs.total_estimate
FROM 
    ranked_sales r
JOIN 
    customer_stats cs ON r.sales_rank <= 10
WHERE 
    r.total_sales > (SELECT AVG(total_sales) FROM ranked_sales WHERE total_sales IS NOT NULL)
ORDER BY 
    r.total_sales DESC;
