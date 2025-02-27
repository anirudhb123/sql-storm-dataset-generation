
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        1 AS level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > 0  -- Arbitrary condition to filter data

    UNION ALL

    SELECT 
        ws.sold_date_sk,
        ws.item_sk,
        ws.order_number,
        ws.quantity,
        ws.sales_price,
        ws.ext_sales_price,
        cte.level + 1
    FROM 
        web_sales ws
    JOIN 
        Sales_CTE cte ON ws.sold_date_sk = cte.ws_sold_date_sk
    WHERE 
        level < 3  -- Limit the recursive level
),
Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(coalesce(ws.ws_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
Top_Customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales
    FROM 
        Customer_Sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.sales_rank <= 10
),
Sales_Join AS (
    SELECT 
        t.c_first_name,
        t.c_last_name,
        SUM(s.ws_ext_sales_price) AS total_sales,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        Top_Customers t
    JOIN 
        web_sales s ON t.c_customer_sk = s.ws_bill_customer_sk
    JOIN 
        date_dim d ON s.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        t.c_first_name, t.c_last_name, d.d_year, d.d_month_seq, d.d_week_seq
)
SELECT 
    sj.c_first_name,
    sj.c_last_name,
    sj.total_sales,
    d.d_month_seq,
    d.d_week_seq,
    ROW_NUMBER() OVER (PARTITION BY sj.d_year ORDER BY sj.total_sales DESC) AS annual_rank,
    CASE 
        WHEN sj.total_sales IS NULL THEN 'No Sales'
        WHEN sj.total_sales < 1000 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    Sales_Join sj
JOIN 
    date_dim d ON sj.d_year = d.d_year
WHERE 
    sj.total_sales IS NOT NULL
ORDER BY 
    sj.total_sales DESC;
