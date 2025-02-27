
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 2000 
        AND c.c_preferred_cust_flag = 'Y'
        AND ws.ws_sold_date_sk >= (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2022
        )
    GROUP BY 
        ws.bill_customer_sk, 
        ws.web_site_sk
), total_profits AS (
    SELECT 
        SUM(total_net_profit) AS grand_total_profit
    FROM 
        ranked_sales
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    ca.ca_state,
    r.r_reason_desc,
    COALESCE(ws.ws_net_paid_inc_tax, 0) AS total_spent,
    COALESCE(sr.total_returned_quantity, 0) AS total_returns,
    TP.grand_total_profit
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    (
        SELECT 
            wr.returning_customer_sk,
            SUM(wr.return_quantity) AS total_returned_quantity
        FROM 
            web_returns wr
        GROUP BY 
            wr.returning_customer_sk
    ) sr ON c.c_customer_sk = sr.returning_customer_sk
JOIN 
    reason r ON r.r_reason_sk = (
        SELECT 
            cr.reason_sk 
        FROM 
            catalog_returns cr 
        WHERE 
            cr.returning_customer_sk = c.c_customer_sk 
        ORDER BY 
            cr.returned_date_sk DESC 
        LIMIT 1
    )
CROSS JOIN 
    total_profits TP
WHERE 
    c.c_customer_sk IN (SELECT bill_customer_sk FROM web_sales WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim))
ORDER BY 
    total_spent DESC
LIMIT 100;
