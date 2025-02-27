
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_sales_price) AS total_sales_amount,
        CURRENT_DATE AS calculation_date
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1)
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_sold_quantity,
        SUM(cs_sales_price) AS total_sales_amount,
        CURRENT_DATE AS calculation_date
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1)
    GROUP BY 
        cs_item_sk
), 
item_ranked AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        s.total_sold_quantity,
        s.total_sales_amount,
        RANK() OVER (ORDER BY s.total_sales_amount DESC) AS sales_rank
    FROM 
        item i
    JOIN 
        sales_summary s ON i.i_item_sk = s.ws_item_sk
), 
qualified_items AS (
    SELECT 
        ir.i_item_id,
        ir.i_item_desc,
        ir.total_sold_quantity,
        ir.total_sales_amount,
        ir.sales_rank
    FROM 
        item_ranked ir
    WHERE 
        ir.sales_rank <= 10 
)

SELECT 
    qi.i_item_id,
    qi.i_item_desc,
    qi.total_sold_quantity,
    qi.total_sales_amount,
    COALESCE(wp.wp_access_date_sk, 0) AS access_date_sk,
    COALESCE(wr.wr_return_quantity, 0) AS return_quantity,
    CASE 
        WHEN qi.total_sales_amount IS NOT NULL THEN qi.total_sales_amount / NULLIF(qi.total_sold_quantity, 0) 
        ELSE 0 
    END AS average_sales_price
FROM 
    qualified_items qi
LEFT JOIN 
    web_page wp ON wp.wp_web_page_sk = (SELECT wp_web_page_sk FROM web_returns wr WHERE wr.wr_item_sk = qi.i_item_id ORDER BY wr.wr_returned_date_sk DESC LIMIT 1)
LEFT JOIN 
    web_returns wr ON wr.wr_item_sk = qi.i_item_id
WHERE 
    (qi.total_sold_quantity > 5 AND qi.total_sales_amount > 100) OR (qi.total_sales_amount IS NOT NULL AND qi.total_sold_quantity < 20)
ORDER BY 
    qi.total_sales_amount DESC;
