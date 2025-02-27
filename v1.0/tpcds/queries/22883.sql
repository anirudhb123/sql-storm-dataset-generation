
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (
            SELECT MAX(ws_sub.ws_sold_date_sk)
            FROM web_sales ws_sub
            WHERE ws_sub.ws_item_sk = ws.ws_item_sk
        )
),
HighValueReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity > 0
    GROUP BY 
        cr.cr_item_sk
),
AddressData AS (
    SELECT 
        ca.ca_address_sk,
        COALESCE(ca.ca_city, 'Unknown City') AS city,
        MAX(CASE 
            WHEN ca.ca_state = 'CA' THEN 1 
            ELSE 0 
        END) AS is_california
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_address_sk
)
SELECT 
    cs.cs_order_number,
    cs.cs_item_sk,
    COALESCE(rs.price_rank, 0) AS sales_price_rank,
    COALESCE(hv.total_return_amount, 0) AS total_return_value,
    ad.city,
    CASE 
        WHEN ad.is_california = 1 THEN 'California'
        ELSE 'Other'
    END AS address_type
FROM 
    catalog_sales cs
FULL OUTER JOIN RankedSales rs ON cs.cs_order_number = rs.ws_order_number AND cs.cs_item_sk = rs.ws_item_sk
LEFT JOIN HighValueReturns hv ON cs.cs_item_sk = hv.cr_item_sk
JOIN AddressData ad ON ad.ca_address_sk = (
    SELECT c.c_current_addr_sk 
    FROM customer c 
    WHERE c.c_customer_sk = cs.cs_bill_customer_sk
)
WHERE 
    (cs.cs_net_paid > (
        SELECT AVG(cs_sub.cs_net_paid)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_sold_date_sk = cs.cs_sold_date_sk
    ) OR hv.total_return_amount IS NOT NULL)
AND ad.city IS NOT NULL
ORDER BY 
    cs.cs_order_number, 
    sales_price_rank DESC;
