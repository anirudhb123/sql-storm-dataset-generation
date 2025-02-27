
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
return_summary AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_returns
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
sales_with_returns AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        (cs.total_sales - COALESCE(rs.total_returns, 0)) AS net_sales
    FROM 
        customer_sales cs
    LEFT JOIN 
        return_summary rs ON cs.c_customer_sk = rs.returning_customer_sk
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY net_sales > 0 ORDER BY net_sales DESC) AS sales_rank
    FROM 
        sales_with_returns
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.total_returns,
    s.net_sales,
    CASE 
        WHEN s.net_sales > 500 THEN 'High'
        WHEN s.net_sales > 100 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    w.w_warehouse_name,
    i.i_product_name
FROM 
    ranked_sales s
LEFT JOIN 
    web_sales ws ON s.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    inventory inv ON ws.ws_item_sk = inv.inv_item_sk
LEFT JOIN 
    warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN 
    item i ON inv.inv_item_sk = i.i_item_sk
WHERE 
    warehouse.w_country IS NULL OR w.w_country = 'USA'
ORDER BY 
    s.net_sales DESC, s.sales_rank;
