
WITH CustomerSpend AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
HighSpenders AS (
    SELECT 
        c.c_customer_id,
        cs.ca_zip,
        cs.ca_city,
        cs.ca_state,
        cs.ca_country,
        cs.ca_county,
        ROW_NUMBER() OVER (PARTITION BY cs.ca_zip ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerSpend cs
    JOIN 
        customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        cs.total_spent > (
            SELECT AVG(total_spent) FROM CustomerSpend
        )
)
SELECT 
    h.c_customer_id,
    h.ca_zip,
    h.ca_city,
    h.ca_state,
    h.ca_country,
    h.ca_county
FROM 
    HighSpenders h
WHERE 
    h.rank <= 5
ORDER BY 
    h.ca_zip, h.total_spent DESC;
