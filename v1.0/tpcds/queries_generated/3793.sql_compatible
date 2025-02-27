
WITH sales_summary AS (
    SELECT 
        ws.item_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.item_sk
),
return_summary AS (
    SELECT 
        wr.item_sk,
        SUM(wr.return_amt) AS total_returns
    FROM 
        web_returns wr
    JOIN 
        date_dim dd ON wr.returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        wr.item_sk
),
combined_summary AS (
    SELECT 
        ss.item_sk,
        ss.total_sales,
        COALESCE(rs.total_returns, 0) AS total_returns,
        ss.total_sales - COALESCE(rs.total_returns, 0) AS net_sales
    FROM 
        sales_summary ss
    LEFT JOIN 
        return_summary rs ON ss.item_sk = rs.item_sk
),
ranked_sales AS (
    SELECT 
        cs.item_sk,
        cs.net_sales,
        RANK() OVER (ORDER BY cs.net_sales DESC) AS sales_rank
    FROM 
        combined_summary cs
)
SELECT 
    i.item_id,
    i.item_desc,
    r.sales_rank,
    r.net_sales
FROM 
    ranked_sales r
JOIN 
    item i ON r.item_sk = i.item_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.sales_rank;
