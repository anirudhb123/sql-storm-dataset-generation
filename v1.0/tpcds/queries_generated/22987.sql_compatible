
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk,
        COUNT(*) OVER (PARTITION BY ws.ws_item_sk) AS sales_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT d.d_date_sk 
                               FROM date_dim d 
                               WHERE d.d_date = '2002-10-01')
        AND ws.ws_sales_price IS NOT NULL
),
PromotionsData AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_id,
        p.p_discount_active,
        COUNT(p.p_promo_sk) AS promo_count
    FROM 
        promotion p
    WHERE 
        p.p_start_date_sk <= (SELECT d.d_date_sk 
                               FROM date_dim d 
                               WHERE d.d_date = '2002-10-01')
        AND (p.p_end_date_sk IS NULL OR p.p_end_date_sk >= (SELECT d.d_date_sk 
                                                              FROM date_dim d 
                                                              WHERE d.d_date = '2002-10-01'))
    GROUP BY 
        p.p_promo_sk, p.p_promo_id, p.p_discount_active
),
HighValueSales AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_net_paid_inc_tax) AS total_sales,
        SUM(s.ss_ext_discount_amt) AS total_discount
    FROM 
        store_sales s
    WHERE 
        s.ss_customer_sk IN (SELECT c.c_customer_sk 
                              FROM customer c 
                              WHERE c.c_birth_year >= 1980)
    GROUP BY 
        s.ss_item_sk
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    hs.total_sales,
    hs.total_discount,
    COALESCE(pd.promo_count, 0) AS active_promotions,
    rks.rnk
FROM 
    item
LEFT JOIN 
    HighValueSales hs ON item.i_item_sk = hs.ss_item_sk
LEFT JOIN 
    PromotionsData pd ON pd.p_discount_active = 'Y'
JOIN 
    RankedSales rks ON item.i_item_sk = rks.ws_item_sk
WHERE 
    (hs.total_sales IS NOT NULL OR pd.promo_count IS NOT NULL)
    AND item.i_current_price > (
        SELECT AVG(i.i_current_price) 
        FROM item i 
        WHERE i.i_class IN (
            SELECT DISTINCT i.i_class 
            FROM item 
            WHERE i.i_current_price IS NOT NULL
        )
    )
ORDER BY 
    hs.total_sales DESC, rks.rnk
LIMIT 100;
