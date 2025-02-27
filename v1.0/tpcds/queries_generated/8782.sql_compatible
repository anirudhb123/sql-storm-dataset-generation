
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
), PromotionStats AS (
    SELECT 
        p.p_promo_id,
        COUNT(DISTINCT ws.ws_order_number) AS orders_with_promo,
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_id
), StoreReturns AS (
    SELECT 
        sr.sr_store_sk,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_store_sk
)
SELECT 
    ca.ca_city,
    SUM(cs.total_sales) AS total_sales,
    SUM(ps.promo_sales) AS total_promo_sales,
    SUM(sr.total_return_amount) AS total_returns,
    COUNT(DISTINCT cs.c_customer_id) AS unique_customers
FROM 
    customer_address ca
JOIN 
    CustomerSales cs ON cs.c_customer_id IN (
        SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk = ca.ca_address_sk
    )
JOIN 
    PromotionStats ps ON TRUE
JOIN 
    StoreReturns sr ON ca.ca_address_sk = sr.sr_store_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
