
WITH RECURSIVE CTE_Customer_Spending AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spending,
        1 AS level
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spending,
        prev.level + 1
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        CTE_Customer_Spending prev ON c.c_customer_sk = prev.c_customer_sk
    WHERE 
        prev.level < 2
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, prev.level
),
Ranked_Spending AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        total_spending,
        RANK() OVER (ORDER BY total_spending DESC) AS spending_rank
    FROM 
        CTE_Customer_Spending c
)
SELECT 
    r.c_customer_sk,
    r.c_first_name,
    r.c_last_name,
    r.total_spending,
    r.spending_rank,
    (SELECT COUNT(DISTINCT ws.ws_item_sk)
     FROM web_sales ws 
     WHERE ws.ws_bill_customer_sk = r.c_customer_sk) AS items_purchased,
    (SELECT COUNT(DISTINCT sr.sr_returned_date_sk)
     FROM store_returns sr 
     WHERE sr.sr_customer_sk = r.c_customer_sk
     AND sr.sr_return_quantity > 0) AS returns_count
FROM 
    Ranked_Spending r
WHERE 
    r.spending_rank <= 10
ORDER BY 
    r.total_spending DESC
FETCH FIRST 5 ROWS ONLY;
