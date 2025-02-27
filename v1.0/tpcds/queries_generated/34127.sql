
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.ticket_number,
        ss.quantity,
        ss.sales_price,
        ss.net_profit,
        1 AS level
    FROM 
        store_sales ss
    WHERE 
        ss.sold_date_sk = (SELECT MAX(ss_inner.sold_date_sk) FROM store_sales ss_inner)
    UNION ALL
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.ticket_number,
        ss.quantity,
        ss.sales_price,
        ss.net_profit,
        level + 1
    FROM 
        store_sales ss
    JOIN 
        SalesCTE s ON ss.ticket_number = s.ticket_number
    WHERE 
        s.level < 3 
),
TotalSales AS (
    SELECT 
        c.c_customer_id,
        SUM(s.net_profit) AS total_net_profit,
        COUNT(DISTINCT s.ticket_number) AS ticket_count,
        c.c_birth_year,
        DENSE_RANK() OVER (PARTITION BY c.c_birth_year ORDER BY SUM(s.net_profit) DESC) AS rank_within_age
    FROM 
        customer c
    LEFT JOIN 
        SalesCTE s ON c.c_customer_sk = s.s_item_sk
    GROUP BY 
        c.c_customer_id, c.c_birth_year
),
FilteredSales AS (
    SELECT 
        *,
        CASE 
            WHEN total_net_profit IS NULL THEN 0 
            ELSE total_net_profit 
        END AS adjusted_net_profit
    FROM 
        TotalSales
)
SELECT 
    f.c_customer_id,
    f.total_net_profit,
    f.ticket_count,
    f.c_birth_year,
    f.rank_within_age,
    CASE 
        WHEN f.adjusted_net_profit > 1000 THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    FilteredSales f
WHERE 
    f.rank_within_age <= 10
ORDER BY 
    f.total_net_profit DESC
LIMIT 20;

