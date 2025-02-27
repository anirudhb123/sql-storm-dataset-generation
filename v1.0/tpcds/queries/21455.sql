
WITH RankedPurchases AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_spent,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), FrequentCustomers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(ws.ws_order_number) > 5
), PromotedItems AS (
    SELECT 
        p.p_promo_name,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM 
        promotion p
    JOIN 
        catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name
), CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COALESCE(MAX(ca.ca_zip), 'Unknown') AS max_zip
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    rp.c_first_name,
    rp.c_last_name,
    rp.total_spent,
    COALESCE(fc.order_count, 0) AS total_orders,
    pi.p_promo_name AS promo_name,
    pi.total_quantity_sold,
    ca.ca_city,
    ca.ca_state,
    ca.max_zip
FROM 
    RankedPurchases rp
LEFT JOIN 
    FrequentCustomers fc ON rp.c_customer_sk = fc.c_customer_sk
LEFT JOIN 
    PromotedItems pi ON (rp.total_spent > 1000 AND pi.total_quantity_sold > 50)
JOIN 
    CustomerAddress ca ON rp.c_customer_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = rp.c_customer_sk)
WHERE 
    rp.purchase_rank = 1
ORDER BY 
    rp.total_spent DESC
FETCH FIRST 10 ROWS ONLY;
