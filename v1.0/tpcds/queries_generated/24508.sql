
WITH RankedReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.item_sk,
        sr.customer_sk,
        sr.return_quantity,
        sr.return_amt,
        sr_return_tax,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY sr.returned_date_sk DESC) AS rn
    FROM 
        store_returns sr
    WHERE 
        sr.return_quantity IS NOT NULL AND 
        sr.return_amt IS NOT NULL
),
SalesData AS (
    SELECT 
        ws.item_sk,
        SUM(ws.quantity) AS total_sales,
        AVG(ws.net_profit) AS avg_profit,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.net_profit > 0
    GROUP BY 
        ws.item_sk
),
PromotionalAnalysis AS (
    SELECT 
        p.promo_id,
        SUM(ws.ws_quantity) AS promo_sales
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    WHERE 
        p.discount_active = 'Y'
    GROUP BY 
        p.promo_id
),
CombinedResults AS (
    SELECT 
        cr.returned_date_sk,
        cr.return_time_sk,
        dr.d_date AS return_date,
        sr.item_sk,
        rs.total_sales,
        rs.avg_profit,
        rd.promo_id,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.return_amt) AS total_return_amt,
        SUM(cr.return_tax) AS total_return_tax
    FROM 
        RankedReturns cr
    JOIN 
        date_dim dr ON cr.returned_date_sk = dr.d_date_sk
    LEFT JOIN 
        SalesData rs ON cr.item_sk = rs.item_sk
    LEFT JOIN 
        PromotionalAnalysis rd ON cr.item_sk = rd.promo_id
    GROUP BY 
        cr.returned_date_sk, cr.return_time_sk, dr.d_date, sr.item_sk, rs.total_sales, 
        rs.avg_profit, rd.promo_id
)
SELECT 
    cb.*,
    CASE 
        WHEN cb.total_return_quantity > 0 THEN 'Excess Returns'
        ELSE 'Normal Sales Activity'
    END AS sales_category,
    CONCAT('Returned: ', COALESCE(TO_CHAR(cb.total_return_amt, '9,999,990.99'), '0.00')) AS formatted_return_amt
FROM 
    CombinedResults cb
WHERE 
    cb.total_sales IS NOT NULL OR 
    cb.total_return_quantity IS NOT NULL
ORDER BY 
    cb.return_date DESC, cb.total_return_quantity DESC;
