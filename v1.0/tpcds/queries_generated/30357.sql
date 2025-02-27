
WITH RECURSIVE ItemReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(wr_return_quantity) AS total_web_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_value,
        ROW_NUMBER() OVER (PARTITION BY wr_item_sk ORDER BY SUM(wr_return_amt_inc_tax) DESC) AS rn
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk > (
            SELECT MAX(d_date_sk) 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 6
        )
    GROUP BY 
        wr_item_sk
),
TopReturnedItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        item.i_current_price,
        ir.total_web_returns,
        ir.total_return_value
    FROM 
        item AS item
    JOIN 
        ItemReturns AS ir ON item.i_item_sk = ir.wr_item_sk
    WHERE 
        ir.rn <= 10
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS total_sales_count
    FROM 
        store_sales AS ss
    GROUP BY 
        ss.ss_item_sk
), 
Promotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        COUNT(ws.ws_order_number) AS promo_sales_count
    FROM 
        promotion AS p
    LEFT JOIN 
        web_sales AS ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id, p.p_promo_name
)
SELECT 
    t.item_id,
    t.item_desc,
    t.current_price,
    COALESCE(s.total_sales, 0) AS total_store_sales,
    COALESCE(s.total_sales_count, 0) AS sales_count,
    r.total_web_returns,
    r.total_return_value,
    p.promo_sales_count
FROM 
    TopReturnedItems AS t
LEFT JOIN 
    StoreSalesSummary AS s ON t.i_item_id = s.ss_item_sk
LEFT JOIN 
    ItemReturns AS r ON t.i_item_id = r.wr_item_sk
LEFT JOIN 
    Promotions AS p ON t.i_item_id = p.p_promo_id
WHERE 
    (r.total_web_returns > 5 OR s.total_sales > 1000)
ORDER BY 
    r.total_return_value DESC, 
    s.total_sales DESC;
