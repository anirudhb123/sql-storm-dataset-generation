
WITH RankedSales AS (
    SELECT 
        ws.item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY ws_sales_price DESC) AS rank,
        COALESCE(NULLIF(ws_ext_discount_amt, 0), WS.net_paid_inc_tax * 0.1) AS effective_discount
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 AND 
        EXTRACT(YEAR FROM CURRENT_DATE) - i.i_rec_start_date_year = 2023
), 
FilteredReturns AS (
    SELECT 
        wr_return_quantity,
        wr_returned_date_sk,
        wr_reason_sk,
        SUM(wr_returned_quantity) OVER (PARTITION BY wr_reason_sk) AS total_returned
    FROM 
        web_returns 
    WHERE 
        wr_return_quantity IS NOT NULL
    AND 
        wr_returned_quantity > 1
),
RecentPromotions AS (
    SELECT 
        p.p_promo_id,
        p.p_promo_name,
        p.p_discount_active,
        DATEDIFF(DAY, p.p_start_date_sk, p.p_end_date_sk) AS promo_duration_days
    FROM 
        promotion p
    WHERE 
        p.p_discount_active = 'Y' AND
        p.p_channel_email = 'Y'
)
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT cs_order_number) AS total_orders,
    SUM(ws.sales_price - effective_discount) AS total_spent,
    MAX(RankSales.rank) AS highest_rank,
    SUM(CASE WHEN FilteredReturns.wr_returned_quantity IS NULL THEN 0 ELSE FilteredReturns.total_returned END) AS total_returns,
    AVG(RecentPromotions.promo_duration_days) AS average_promo_duration
FROM 
    customer c
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    RankedSales ON ws.ws_item_sk = RankedSales.item_sk
LEFT JOIN 
    FilteredReturns ON ws.ws_order_number = FilteredReturns.wr_order_number
LEFT JOIN 
    RecentPromotions ON ws.ws_order_number = RecentPromotions.p_promo_id
WHERE 
    c.c_birth_year IS NOT NULL 
    AND c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_gender = 'F')
GROUP BY 
    c.c_customer_id
HAVING 
    AVG(ws.net_paid_inc_tax) > (SELECT AVG(ws.net_paid_inc_tax) FROM web_sales ws);
