
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '1 year') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_sales,
        COALESCE((
            SELECT 
                AVG(ss_net_paid) 
            FROM 
                store_sales 
            WHERE 
                ss_item_sk = rs.ws_item_sk
        ), 0) AS avg_store_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
)
SELECT 
    t.ws_item_sk,
    t.i_item_desc,
    t.total_quantity,
    t.total_sales,
    CASE 
        WHEN t.avg_store_sales > 0 THEN (t.total_sales / t.avg_store_sales) * 100 
        ELSE NULL 
    END AS sales_ratio,
    d.d_month AS sale_month,
    COUNT(DISTINCT ws_order_number) AS number_of_orders
FROM 
    TopItems t
LEFT JOIN 
    web_sales ws ON t.ws_item_sk = ws.ws_item_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    t.ws_item_sk, t.i_item_desc, t.total_quantity, t.total_sales, t.avg_store_sales, d.d_month
ORDER BY 
    sales_ratio DESC NULLS LAST;
