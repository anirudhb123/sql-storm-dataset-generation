
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id, 
        COUNT(DISTINCT sr_returned_date_sk) AS total_returns, 
        SUM(sr_return_quantity) AS total_returned_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
), 
PromotionsData AS (
    SELECT 
        p.p_promo_name, 
        SUM(ws_ext_sales_price) AS total_sales, 
        SUM(ws_ext_discount_amt) AS total_discounts
    FROM 
        web_sales ws
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        p.p_promo_name
), 
ActivePromotions AS (
    SELECT 
        pd.p_promo_name, 
        pd.total_sales, 
        pd.total_discounts, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        PromotionsData pd
    WHERE 
        pd.total_sales IS NOT NULL
)

SELECT 
    cr.c_customer_id, 
    COALESCE(cr.total_returns, 0) AS total_returns, 
    COALESCE(cr.total_returned_quantity, 0) AS total_returned_qty,
    ap.p_promo_name,
    ap.total_sales,
    ap.total_discounts,
    CASE 
        WHEN cr.total_returns IS NULL AND ap.total_sales IS NULL THEN 'No Activity'
        WHEN cr.total_returns IS NOT NULL AND ap.sales_rank <= 5 THEN 'Top Customer with Active Promotion'
        WHEN cr.total_returns IS NOT NULL THEN 'Active Customer'
        ELSE 'Inactive Customer'
    END AS customer_status
FROM 
    CustomerReturns cr
FULL OUTER JOIN 
    ActivePromotions ap ON cr.c_customer_id = (SELECT MAX(c.c_customer_id) FROM customer c WHERE c.c_customer_sk = cr.c_customer_id)
WHERE 
    (cr.total_returns IS NOT NULL OR ap.total_sales IS NOT NULL)
ORDER BY 
    customer_status DESC, 
    total_sales DESC NULLS LAST;
