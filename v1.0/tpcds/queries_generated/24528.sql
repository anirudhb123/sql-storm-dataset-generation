
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year >= 2021
    GROUP BY 
        ws.web_site_sk
),
FrequentReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_item_sk) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
    HAVING 
        COUNT(sr_item_sk) > 5
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_email_address
    ORDER BY 
        total_spent DESC
    LIMIT 10
)
SELECT 
    ca.ca_city,
    SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS total_sales,
    COALESCE(r.return_count, 0) AS total_returns,
    CASE 
        WHEN SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) > 1000 THEN 'High Value Area'
        ELSE 'Standard Area'
    END AS area_type,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    DENSE_RANK() OVER (ORDER BY SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) DESC) AS sales_rank
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    FrequentReturns r ON ws.ws_item_sk = r.sr_item_sk
WHERE 
    ca.ca_state IS NOT NULL AND 
    ca.ca_city LIKE 'San%'
GROUP BY 
    ca.ca_city
HAVING 
    SUM(COALESCE(ws.ws_net_paid_inc_tax, 0)) IS NOT NULL
ORDER BY 
    total_sales DESC NULLS LAST
LIMIT 20;
