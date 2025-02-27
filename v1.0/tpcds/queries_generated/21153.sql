
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(sr_return_amt, 0) + COALESCE(sr_return_tax, 0)) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
Promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_id,
        SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_promotions,
        COUNT(DISTINCT p.p_item_sk) AS items_promoted
    FROM 
        promotion p
    GROUP BY 
        p.p_promo_sk, p.p_promo_id
),
WebSalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(ps.active_promotions, 0) AS active_promotions,
    ws.total_quantity_sold,
    ws.total_sales,
    CASE 
        WHEN ws.sales_rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    customer c
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
LEFT JOIN 
    Promotions ps ON EXISTS (SELECT 1 FROM promotion p WHERE p.p_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk))
LEFT JOIN 
    WebSalesSummary ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990 
    AND (c.c_preferred_cust_flag = 'Y' OR cr.return_count > 5)
    AND (SELECT COUNT(*) FROM inventory WHERE inv_quantity_on_hand < 10) > 0
ORDER BY 
    total_returned_quantity DESC NULLS LAST 
LIMIT 100 OFFSET 0;
