
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_sales,
        SUM(ws_ext_sales_price) AS total_revenue
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_sold_date_sk, 
        ws_item_sk
),
BestSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        SUM(sales.total_sales) AS total_quantity_sold,
        SUM(sales.total_revenue) AS total_revenue_generated,
        RANK() OVER (ORDER BY SUM(sales.total_revenue) DESC) AS sales_rank
    FROM 
        SalesCTE AS sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_id, item.i_item_desc
)
SELECT 
    items.i_item_id,
    items.i_item_desc,
    items.total_quantity_sold,
    items.total_revenue_generated,
    (SELECT COUNT(*) FROM BestSellingItems) AS total_best_selling_items
FROM 
    BestSellingItems AS items
WHERE 
    items.sales_rank <= 10
ORDER BY 
    items.total_revenue_generated DESC;

-- Including outer join with customer purchase details
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_web_quantity,
    COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_quantity,
    COALESCE(SUM(ss.ss_quantity), 0) AS total_store_quantity,
    CASE WHEN COUNT(DISTINCT ws.ws_order_number) > 0 THEN 'Purchased' ELSE 'Not Purchased' END AS purchase_status
FROM 
    customer AS c
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name
HAVING 
    (total_web_quantity + total_catalog_quantity + total_store_quantity) > 0
ORDER BY 
    total_web_quantity DESC
LIMIT 50;
