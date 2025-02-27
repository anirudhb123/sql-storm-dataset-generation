
WITH RECURSIVE CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_return_quantity,
        COUNT(wr.return_order_number) AS total_returns,
        SUM(wr.return_amt) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY SUM(wr.return_amt) DESC) AS rn
    FROM web_returns wr
    WHERE wr.returning_customer_sk IS NOT NULL
    GROUP BY wr.returning_customer_sk
    HAVING SUM(wr.return_quantity) > 0
),
StoreSalesSummary AS (
    SELECT 
        s_store_sk,
        COUNT(ss.ticket_number) AS total_transactions,
        SUM(ss.ext_sales_price) AS total_sales,
        SUM(ss.ext_discount_amt) AS total_discount,
        AVG(ss.sales_price) AS avg_sales_price,
        SUM(ss.ext_sales_price) - SUM(ss.ext_discount_amt) AS net_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ext_sales_price) DESC) AS store_rank
    FROM store_sales ss
    JOIN store s ON ss.store_sk = s.s_store_sk
    WHERE s.s_country = 'USA'
    GROUP BY s_store_sk
),
ItemPromotions AS (
    SELECT 
        p.p_item_sk,
        COUNT(DISTINCT p.p_promo_id) AS promotion_count,
        SUM(p.p_cost) AS total_promo_cost
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY p.p_item_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ss.avg_sales_price) AS avg_sales_per_store,
    SUM(COALESCE(cr.total_return_quantity, 0)) AS total_return_quantity,
    SUM(COALESCE(cr.total_returns, 0)) AS total_returns,
    SUM(COALESCE(cr.total_return_amount, 0)) AS total_return_amount,
    SUM(promotion_count) AS total_promotions,
    SUM(total_promo_cost) AS total_promotion_spent 
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN CustomerReturns cr ON cr.returning_customer_sk = c.c_customer_sk
LEFT JOIN StoreSalesSummary ss ON ss.store_rank <= 5
LEFT JOIN ItemPromotions ip ON ip.p_item_sk IN (
    SELECT i.i_item_sk 
    FROM item i 
    WHERE i.i_current_price >= 10 
    AND EXISTS (
        SELECT 1 
        FROM promotion p 
        WHERE p.p_item_sk = i.i_item_sk AND p.p_discount_active = 'Y'
    )
)
WHERE (c.c_birth_month BETWEEN 1 AND 6 OR c.c_birth_month IS NULL)
GROUP BY c.c_customer_id, ca.ca_city
HAVING SUM(COALESCE(ss.total_sales, 0)) > 1000
ORDER BY total_return_quantity DESC NULLS LAST;
