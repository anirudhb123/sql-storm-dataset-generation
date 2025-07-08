
WITH RankedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2001)
    GROUP BY cs.cs_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(DISTINCT sr.sr_customer_sk) AS return_customers_count,
        SUM(sr.sr_return_quantity) AS total_returned_quantity
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY sr.sr_item_sk
),
EligiblePromotions AS (
    SELECT 
        p.p_item_sk,
        SUM(p.p_cost) AS total_cost,
        COUNT(DISTINCT p.p_promo_id) AS promo_count
    FROM promotion p
    JOIN RankedSales rs ON p.p_item_sk = rs.cs_item_sk
    WHERE p.p_start_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2001)
    AND p.p_end_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2001)
    GROUP BY p.p_item_sk
)
SELECT 
    i.i_item_sk,
    i.i_item_desc,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(cr.return_customers_count, 0) AS return_customers_count,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(ep.total_cost, 0) AS total_cost,
    COALESCE(ep.promo_count, 0) AS promo_count
FROM item i
LEFT JOIN RankedSales rs ON i.i_item_sk = rs.cs_item_sk AND rs.sales_rank = 1
LEFT JOIN CustomerReturns cr ON i.i_item_sk = cr.sr_item_sk
LEFT JOIN EligiblePromotions ep ON i.i_item_sk = ep.p_item_sk
WHERE (i.i_current_price - COALESCE(ep.total_cost, 0)) > 5
AND (i.i_rec_start_date IS NULL OR i.i_rec_end_date IS NULL OR i.i_rec_start_date <= TO_DATE('2002-10-01'))
ORDER BY total_sales DESC, return_customers_count DESC
LIMIT 50 OFFSET (SELECT COUNT(*) FROM item) * RANDOM();
