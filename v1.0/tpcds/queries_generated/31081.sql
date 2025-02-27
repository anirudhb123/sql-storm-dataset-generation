
WITH RECURSIVE Sales_CTE AS (
    SELECT
        s_order_number,
        SUM(ss_net_profit) AS total_net_profit,
        COUNT(ss_ticket_number) AS total_tickets,
        RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS rank
    FROM store_sales
    GROUP BY s_order_number
),
Customer_Summary AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_purchases
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
)
SELECT
    cs.c_customer_sk,
    cs.cd_gender,
    cs.total_sales,
    COALESCE(s.rank, 0) AS sales_rank,
    CASE
        WHEN cs.total_purchases > 10 THEN 'Frequent Buyer'
        WHEN cs.total_purchases BETWEEN 5 AND 10 THEN 'Moderate Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_category
FROM Customer_Summary cs
LEFT JOIN (
    SELECT
        ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS rank,
        s_order_number
    FROM Sales_CTE
    WHERE total_net_profit > 1000
) s ON cs.c_customer_sk = s.s_order_number
WHERE cs.total_sales IS NOT NULL
ORDER BY cs.total_sales DESC
LIMIT 100;
