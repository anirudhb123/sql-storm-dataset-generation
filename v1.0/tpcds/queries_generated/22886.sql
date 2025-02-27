
WITH RECURSIVE AddressCTE AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state 
    FROM 
        customer_address 
    WHERE 
        ca_state IS NOT NULL
    UNION ALL
    SELECT 
        a.ca_address_sk, 
        a.ca_city, 
        a.ca_state 
    FROM 
        customer_address a
    JOIN 
        AddressCTE ac ON a.ca_city = ac.ca_city AND a.ca_state IS NOT NULL
    WHERE 
        a.ca_address_sk <> ac.ca_address_sk
),
RankedSales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ad.ca_city,
    ad.ca_state,
    COALESCE(r.total_sales, 0) AS total_sales,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Customer' 
        ELSE 'Regular Customer' 
    END AS customer_type,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    STRING_AGG(DISTINCT p.p_promo_name, ', ') AS promotions_used
FROM 
    customer c
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
LEFT JOIN 
    AddressCTE ad ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN 
    RankedSales r ON c.c_customer_sk = r.ws_bill_customer_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk 
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') 
    OR (cd.cd_gender = 'M' AND cd.cd_marital_status IS NULL) 
    AND (ad.ca_state IN ('NY', 'CA') OR ad.ca_city IS NULL)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ad.ca_city, ad.ca_state, r.total_sales, r.sales_rank
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5 OR r.total_sales IS NULL
ORDER BY 
    total_sales DESC
LIMIT 100;
