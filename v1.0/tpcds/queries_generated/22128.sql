
WITH Revenue AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discounts,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
Returns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_returned_amount,
        COUNT(wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
ProductPerformances AS (
    SELECT 
        i.i_item_id,
        COALESCE(r.total_sales, 0) AS total_sales,
        COALESCE(r.total_discounts, 0) AS total_discounts,
        COALESCE(re.total_returned_amount, 0) AS total_returned_amount,
        COALESCE(re.total_returns, 0) AS total_returns,
        (COALESCE(r.total_sales, 0) - COALESCE(r.total_discounts, 0) - COALESCE(re.total_returned_amount, 0)) AS net_revenue
    FROM 
        item i
    LEFT JOIN 
        Revenue r ON i.i_item_sk = r.ws_item_sk
    LEFT JOIN 
        Returns re ON i.i_item_sk = re.wr_item_sk
),
RankedPerformance AS (
    SELECT 
        pp.i_item_id,
        pp.net_revenue,
        RANK() OVER (ORDER BY pp.net_revenue DESC) AS revenue_rank
    FROM 
        ProductPerformances pp
)
SELECT 
    r.i_item_id,
    r.net_revenue,
    CASE 
        WHEN r.revenue_rank <= 10 THEN 'Top 10 Items'
        WHEN r.revenue_rank BETWEEN 11 AND 20 THEN 'Top 20 Items'
        ELSE 'Below Top 20'
    END AS performance_category,
    NULLIF(r.net_revenue / NULLIF(pp.total_orders, 0), 0) AS revenue_per_order
FROM 
    RankedPerformance r
JOIN 
    ProductPerformances pp ON r.i_item_id = pp.i_item_id
WHERE 
    pp.total_returns < (SELECT AVG(total_returns) FROM Returns)
    AND pp.total_orders > 0
ORDER BY 
    r.net_revenue DESC;
