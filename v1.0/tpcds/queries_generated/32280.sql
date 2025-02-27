
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.sold_date_sk, 
        ws.item_sk, 
        ws.quantity, 
        ws.sales_price, 
        ws.ext_sales_price,
        1 AS level
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    UNION ALL
    SELECT 
        ws.sold_date_sk, 
        ws.item_sk, 
        ws.quantity, 
        ws.sales_price, 
        ws.ext_sales_price,
        cte.level + 1
    FROM 
        web_sales ws
    JOIN 
        SalesCTE cte ON ws.sold_date_sk = cte.sold_date_sk AND cte.item_sk = ws.item_sk
    WHERE 
        cte.level < 5
),
TotalSales AS (
    SELECT 
        wd.d_month_seq,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.bill_customer_sk) AS customer_count,
        COALESCE(SUM(prom.p_cost), 0) AS total_discount
    FROM 
        web_sales ws
    LEFT JOIN 
        promotion prom ON ws.promo_sk = prom.p_promo_sk
    JOIN 
        date_dim wd ON ws.sold_date_sk = wd.d_date_sk
    WHERE 
        wd.d_year = 2023
    GROUP BY 
        wd.d_month_seq
)
SELECT 
    ts.d_month_seq,
    ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS rank,
    ts.total_sales,
    ts.customer_count,
    ts.total_discount,
    CASE 
        WHEN ts.total_sales > 10000 THEN 'High'
        WHEN ts.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    TotalSales ts
ORDER BY 
    ts.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
