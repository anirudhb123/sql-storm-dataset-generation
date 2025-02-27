
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_order_number,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_paid DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_net_paid IS NOT NULL
        AND ws_net_paid < (SELECT AVG(ws_net_paid) FROM web_sales)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        cs_bill_customer_sk,
        SUM(cs_net_paid) AS total_sales,
        COALESCE(cr.total_returned_quantity, 0) AS total_returns,
        COUNT(cs_order_number) AS total_orders
    FROM 
        catalog_sales cs
    LEFT JOIN 
        CustomerReturns cr ON cs_bill_customer_sk = cr.wr_returning_customer_sk
    GROUP BY 
        cs_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    MAX(CASE WHEN rs.rn = 1 THEN rs.ws_net_paid ELSE NULL END) AS max_spent,
    s.total_sales,
    s.total_returns,
    s.total_orders,
    CASE 
        WHEN s.total_returns > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_returns,
    COALESCE(SUM(p.p_discount_active = 'Y'), 0) AS active_promotions,
    COALESCE(SUM(p.p_discount_active = 'N'), 0) AS inactive_promotions
FROM 
    customer c
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN 
    SalesWithReturns s ON c.c_customer_sk = s.cs_bill_customer_sk
LEFT JOIN 
    promotion p ON rs.ws_order_number = p.p_promo_sk
WHERE 
    (s.total_sales IS NOT NULL OR rs.ws_order_number IS NOT NULL)
    AND c.c_birth_month = 12 -- customers born in December
GROUP BY 
    c.c_customer_id, s.total_sales, s.total_returns, s.total_orders
ORDER BY 
    max_spent DESC, c.c_customer_id
LIMIT 100 OFFSET 10;
