
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        SUM(ws_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_item_sk
),
BestSellingItems AS (
    SELECT 
        ir.i_item_sk,
        ir.i_item_desc,
        COALESCE(rs.total_sales, 0) AS web_sales_quantity,
        COALESCE(rs.total_revenue, 0) AS web_sales_revenue
    FROM 
        item ir
    LEFT JOIN 
        RankedSales rs ON ir.i_item_sk = rs.ws_item_sk
    WHERE 
        ir.i_rec_start_date <= '2023-10-01' AND (ir.i_rec_end_date IS NULL OR ir.i_rec_end_date >= '2023-10-01')
)
SELECT 
    b.i_item_desc,
    b.web_sales_quantity,
    b.web_sales_revenue,
    COALESCE((SELECT SUM(sr_return_qty) 
               FROM store_returns sr 
               WHERE sr.sr_item_sk = b.i_item_sk), 0) AS total_returns,
    ROUND(b.web_sales_revenue - COALESCE((SELECT SUM(sr_return_amt_inc_tax) 
                                            FROM store_returns sr 
                                            WHERE sr.sr_item_sk = b.i_item_sk), 0), 2) AS net_revenue,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
    AVG(COALESCE(c.cc_tax_percentage, 0)) AS avg_tax_percentage
FROM 
    BestSellingItems b
LEFT JOIN 
    catalog_sales cs ON b.i_item_sk = cs.cs_item_sk
LEFT JOIN 
    call_center c ON cs.cs_call_center_sk = c.cc_call_center_sk
GROUP BY 
    b.i_item_desc, b.web_sales_quantity, b.web_sales_revenue
HAVING 
    net_revenue > 1000
ORDER BY 
    b.web_sales_revenue DESC;
