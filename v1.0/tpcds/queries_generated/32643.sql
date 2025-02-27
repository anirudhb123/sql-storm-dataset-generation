
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity + S.ws_quantity,
        ws_sales_price,
        ws_net_paid + S.ws_net_paid
    FROM 
        web_sales W
    JOIN 
        SalesCTE S ON W.ws_item_sk = S.ws_item_sk AND W.ws_sold_date_sk = S.ws_sold_date_sk - 1
)

SELECT 
    C.c_customer_id,
    CA.ca_city,
    SUM(WC.ws_quantity) AS total_quantity,
    AVG(WC.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT WC.ws_order_number) AS order_count,
    CASE 
        WHEN SUM(WC.ws_net_paid) IS NULL THEN 'No purchases'
        ELSE CONCAT('Total paid: $', ROUND(SUM(WC.ws_net_paid), 2))
    END AS payment_summary
FROM 
    customer C
LEFT JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
LEFT JOIN 
    web_sales WC ON C.c_customer_sk = WC.ws_bill_customer_sk
JOIN 
    (SELECT DISTINCT ws_item_sk FROM SalesCTE) AS S ON WC.ws_item_sk = S.ws_item_sk
WHERE 
    (CA.ca_city IS NOT NULL OR CA.ca_city <> '')
    AND (C.c_birth_year BETWEEN 1980 AND 1990 OR C.c_email_address IS NOT NULL)
GROUP BY 
    C.c_customer_id, CA.ca_city
HAVING 
    total_quantity > 10
ORDER BY 
    total_quantity DESC
LIMIT 50;
