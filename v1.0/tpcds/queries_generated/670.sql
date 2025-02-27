
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
TotalSales AS (
    SELECT 
        web_site_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        web_site_sk
),
CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spend
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spend,
        RANK() OVER (ORDER BY cs.total_spend DESC) AS customer_rank
    FROM 
        CustomerSpend cs
    WHERE 
        cs.total_spend IS NOT NULL
),
FinalReport AS (
    SELECT 
        ts.c_customer_sk,
        ts.total_spend,
        ts.customer_rank,
        ts.total_spend / NULLIF(ts.customer_rank, 0) AS average_spend_rank
    FROM 
        TopCustomers ts
    WHERE 
        ts.customer_rank <= 10
)

SELECT 
    a.ca_city,
    COALESCE(t.total_sales, 0) AS total_sales_last_30_days,
    COALESCE(f.total_spend, 0) AS customer_spend
FROM 
    customer_address a
LEFT JOIN 
    TotalSales t ON a.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = 
        (SELECT cs.c_customer_sk FROM FinalReport cs WHERE cs.customer_rank = 1 LIMIT 1))
LEFT JOIN 
    FinalReport f ON f.c_customer_sk = (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = a.ca_address_sk)
ORDER BY 
    a.ca_city;
