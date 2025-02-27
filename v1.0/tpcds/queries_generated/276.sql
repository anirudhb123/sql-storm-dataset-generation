
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales s
    JOIN 
        customer c ON s.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, s.ss_sold_date_sk, s.ss_item_sk
), ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        i.i_current_price
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
), DailySales AS (
    SELECT 
        d.d_date_sk,
        SUM(s.ss_sales_price) AS daily_sales
    FROM 
        store_sales s
    JOIN 
        date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date_sk
)
SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    COUNT(r.ss_item_sk) AS items_purchased,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    COALESCE(ds.daily_sales, 0) AS total_daily_sales,
    id.i_item_id,
    id.i_item_desc,
    id.i_brand,
    id.i_category,
    id.i_current_price
FROM 
    RankedSales r
LEFT JOIN 
    DailySales ds ON r.ss_sold_date_sk = ds.d_date_sk
JOIN 
    ItemDetails id ON r.ss_item_sk = id.i_item_sk
WHERE 
    r.total_sales > 1000
    AND r.sales_rank <= 5
ORDER BY 
    total_daily_sales DESC, r.c_customer_id;
