
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING 
        SUM(ws.ws_sales_price) > (
            SELECT AVG(total_sales) FROM RankedSales
            WHERE sales_rank <= 5
        )
),
StoresWithReturns AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount
    FROM 
        store s 
        LEFT JOIN store_returns sr ON s.s_store_sk = sr.s_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
    HAVING 
        COUNT(DISTINCT sr.ticket_number) > 0
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    s.s_store_name,
    COALESCE(swr.total_returns, 0) AS store_returns,
    swr.total_return_amount,
    CASE 
        WHEN hvc.total_spent > 1000 THEN 'High Roller'
        WHEN hvc.total_spent BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    HighValueCustomers hvc
    JOIN StoresWithReturns swr ON swr.s_store_sk = (
        SELECT s.s_store_sk 
        FROM store s 
        ORDER BY RANDOM() LIMIT 1
    )
WHERE 
    EXISTS (
        SELECT 1 
        FROM RankedSales rs 
        WHERE rs.total_sales > 500 
          AND hvc.total_spent > (
              SELECT AVG(total_spent) 
              FROM HighValueCustomers
          )
    )
ORDER BY 
    hvc.total_spent DESC, 
    swr.total_return_amount ASC;
