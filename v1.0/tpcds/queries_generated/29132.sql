
WITH AddressHighlights AS (
    SELECT 
        CA.ca_city,
        CA.ca_state,
        COUNT(DISTINCT C.c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT C.c_first_name || ' ' || C.c_last_name, ', ') AS customer_names
    FROM 
        customer_address CA
    JOIN 
        customer C ON CA.ca_address_sk = C.c_current_addr_sk
    GROUP BY 
        CA.ca_city, CA.ca_state
),
SalesSummary AS (
    SELECT 
        WS.ws_sold_date_sk,
        WS.ws_item_sk,
        SUM(WS.ws_quantity) AS total_quantity,
        SUM(WS.ws_ext_sales_price) AS total_sales
    FROM 
        web_sales WS
    GROUP BY 
        WS.ws_sold_date_sk, WS.ws_item_sk
)
SELECT 
    AH.ca_city,
    AH.ca_state,
    AH.customer_count,
    AH.customer_names,
    SS.total_quantity,
    SS.total_sales
FROM 
    AddressHighlights AH
LEFT JOIN 
    SalesSummary SS ON AH.ca_city = (SELECT DISTINCT ca_city FROM customer_address WHERE ca_address_sk = C.c_current_addr_sk)
                    AND AH.ca_state = (SELECT DISTINCT ca_state FROM customer_address WHERE ca_address_sk = C.c_current_addr_sk)
WHERE 
    AH.customer_count > 0
ORDER BY 
    AH.ca_state, AH.ca_city;
