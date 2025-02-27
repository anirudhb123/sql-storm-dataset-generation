
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT sr.ticket_number) AS returns_count,
        SUM(COALESCE(sr.return_amt, 0)) AS total_returns,
        SUM(COALESCE(sr.return_tax, 0)) AS total_return_tax,
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS total_store_purchases,
        (SELECT COUNT(*) FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk) AS total_web_purchases,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(COALESCE(sr.return_amt, 0)) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.returns_count,
        cs.total_returns,
        cs.total_return_tax,
        cs.total_store_purchases,
        cs.total_web_purchases
    FROM 
        customer_stats cs
    WHERE 
        cs.rn <= 10
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.cd_gender,
    t.total_returns,
    t.total_return_tax,
    COALESCE(CASE 
        WHEN t.total_web_purchases > t.total_store_purchases THEN 'Web'
        ELSE 'Store'
    END, 'No Purchases') AS preferred_channel,
    EXISTS (
        SELECT 1
        FROM web_returns wr 
        WHERE wr.wr_returning_customer_sk = t.c_customer_sk 
        AND wr.wr_return_quantity > (
            SELECT AVG(wr2.wr_return_quantity)
            FROM web_returns wr2
            WHERE wr2.wr_returning_customer_sk = t.c_customer_sk
            AND wr2.wr_returned_date_sk IS NOT NULL
        )
    ) AS above_average_web_return
FROM 
    top_customers t
WHERE 
    t.total_returns > (SELECT AVG(total_returns) FROM top_customers)
ORDER BY 
    t.total_returns DESC;
