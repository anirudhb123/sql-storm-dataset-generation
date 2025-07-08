
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(ss.ss_ticket_number) AS purchase_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
SalesRanked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.purchase_count,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSales cs
), 
HighSpenders AS (
    SELECT 
        h.c_customer_sk,
        h.c_first_name,
        h.c_last_name,
        h.total_spent,
        h.purchase_count
    FROM 
        SalesRanked h
    WHERE 
        h.spending_rank <= 10
)
SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.total_spent,
    COALESCE(dd.d_year, 2023) AS interaction_year,
    CASE 
        WHEN hs.purchase_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type,
    (SELECT 
        AVG(ws.ws_net_paid)
     FROM 
        web_sales ws
     WHERE 
        ws.ws_bill_customer_sk = hs.c_customer_sk
    ) AS avg_web_spent,
    (SELECT 
        COUNT(DISTINCT cs.cs_order_number)
     FROM 
        catalog_sales cs
     WHERE 
        cs.cs_bill_customer_sk = hs.c_customer_sk
    ) AS catalog_order_count
FROM 
    HighSpenders hs
LEFT JOIN 
    date_dim dd ON dd.d_date_sk = (SELECT MAX(ws.ws_sold_date_sk) 
                                    FROM web_sales ws 
                                    WHERE ws.ws_bill_customer_sk = hs.c_customer_sk)
ORDER BY 
    hs.total_spent DESC;
