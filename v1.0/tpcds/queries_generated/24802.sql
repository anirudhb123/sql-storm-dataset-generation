
WITH sales_details AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        SUM(ss.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ticket_number) AS transaction_count,
        AVG(ss.ext_discount_amt) AS avg_discount,
        RANK() OVER (PARTITION BY ss.item_sk ORDER BY SUM(ss.ext_sales_price) DESC) AS sales_rank
    FROM 
        store_sales ss
    JOIN 
        item i ON ss.item_sk = i.i_item_sk
    LEFT JOIN 
        customer c ON ss.customer_sk = c.c_customer_sk
    GROUP BY 
        ss.sold_date_sk, ss.item_sk
),
promotions AS (
    SELECT 
        p.item_sk,
        COUNT(DISTINCT p.promo_sk) AS promo_count
    FROM 
        promotion p
    WHERE 
        p.discount_active = 'Y'
    GROUP BY 
        p.item_sk
),
sales_with_promotions AS (
    SELECT 
        sd.sold_date_sk,
        sd.item_sk,
        sd.total_sales,
        sd.transaction_count,
        sd.avg_discount,
        COALESCE(pr.promo_count, 0) AS promo_count,
        CASE 
            WHEN sd.total_sales > 1000 THEN 'High'
            WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        sales_details sd
    LEFT JOIN 
        promotions pr ON sd.item_sk = pr.item_sk
)
SELECT 
    d.d_date AS sale_date,
    swp.sales_category,
    SUM(swp.total_sales) AS total_sales,
    COUNT(swp.item_sk) AS items_sold,
    AVG(swp.avg_discount) AS average_discount
FROM 
    sales_with_promotions swp
JOIN 
    date_dim d ON swp.sold_date_sk = d.d_date_sk
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    AND (swp.promo_count IS NULL OR swp.promo_count > 2)
GROUP BY 
    d.d_date, swp.sales_category
HAVING 
    SUM(swp.total_sales) > 10000
ORDER BY 
    sale_date DESC, total_sales DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
