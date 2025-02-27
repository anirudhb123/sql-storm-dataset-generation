
WITH CustomerSummary AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        SUM(ss.ss_net_profit) AS total_spent,
        COUNT(ss.ss_ticket_number) AS total_purchases
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status
),
DateRange AS (
    SELECT 
        MIN(d.d_date) AS start_date, 
        MAX(d.d_date) AS end_date
    FROM date_dim d
    WHERE d.d_year = 2023
),
ItemSummary AS (
    SELECT 
        i.i_item_id, 
        i.i_item_desc, 
        COUNT(ss.ss_ticket_number) AS sold_count,
        SUM(ss.ss_net_profit) AS total_revenue
    FROM item i
    JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_id, 
        i.i_item_desc
),
HighSpenders AS (
    SELECT 
        cs.c_customer_sk, 
        cs.c_first_name, 
        cs.c_last_name, 
        cs.total_spent, 
        cs.total_purchases,
        CASE
            WHEN cs.total_spent > 1000 THEN 'High'
            WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS spending_category
    FROM CustomerSummary cs
)

SELECT 
    hs.c_customer_sk, 
    hs.c_first_name, 
    hs.c_last_name, 
    hs.total_spent, 
    hs.spending_category,
    ir.i_item_id AS item_id,
    ir.i_item_desc AS item_desc,
    ir.sold_count,
    ir.total_revenue,
    dr.start_date,
    dr.end_date
FROM HighSpenders hs
JOIN ItemSummary ir ON ir.sold_count > 10
CROSS JOIN DateRange dr
WHERE hs.total_spent IS NOT NULL
ORDER BY hs.total_spent DESC, ir.total_revenue DESC
LIMIT 50;
