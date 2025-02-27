
WITH RECURSIVE CustomerLifetimeValue AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(SUM(ws.ws_net_profit), 0) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        clv.total_sales,
        clv.total_orders,
        RANK() OVER (ORDER BY clv.total_sales DESC) AS customer_rank
    FROM 
        CustomerLifetimeValue clv
    JOIN 
        customer c ON clv.c_customer_sk = c.c_customer_sk
    WHERE 
        clv.total_sales > (SELECT AVG(total_sales) FROM CustomerLifetimeValue)
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.total_orders,
    RANK() OVER (ORDER BY r.total_orders DESC) AS order_rank,
    CASE 
        WHEN r.total_sales > 1000 THEN 'High Value'
        WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    RankedCustomers r
WHERE 
    r.customer_rank <= 10
ORDER BY 
    r.total_sales DESC;

WITH RecentSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        MAX(ws.ws_sold_date_sk) >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE - INTERVAL '30 DAY')
)
SELECT 
    i.i_item_id,
    rv.total_quantity,
    COALESCE(rw.total_sold, 0) AS total_web_sales,
    COALESCE(prod_rank.ranking, 0) AS product_rank,
    CASE 
        WHEN rv.total_quantity > 100 THEN 'Best Seller'
        WHEN rv.total_quantity BETWEEN 50 AND 100 THEN 'Good Seller'
        ELSE 'Needs Attention'
    END AS sales_category
FROM 
    item i
LEFT JOIN 
    RecentSales rv ON i.i_item_sk = rv.ws_item_sk
LEFT JOIN 
    (SELECT 
         cs.cs_item_sk, 
         SUM(cs.cs_net_paid) AS total_sold 
     FROM 
         catalog_sales cs
     GROUP BY 
         cs.cs_item_sk) rw ON i.i_item_sk = rw.cs_item_sk
LEFT JOIN 
    (SELECT 
         i.i_item_id, 
         ROW_NUMBER() OVER (ORDER BY SUM(rv.total_quantity) DESC) AS ranking 
     FROM 
         item i 
     JOIN 
         RecentSales rv ON i.i_item_sk = rv.ws_item_sk 
     GROUP BY 
         i.i_item_id) prod_rank ON i.i_item_id = prod_rank.i_item_id
ORDER BY 
    total_web_sales DESC, 
    total_quantity DESC;
