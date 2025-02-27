
WITH RecentSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as sale_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    ) - 30 AND (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ws_item_sk
),
FrequentBuyers AS (
    SELECT 
        c_customer_sk, 
        COUNT(*) AS purchase_count
    FROM 
        customer 
    JOIN 
        web_sales ON ws_bill_customer_sk = c_customer_sk
    GROUP BY 
        c_customer_sk
    HAVING 
        COUNT(*) > (
            SELECT AVG(purchase_count) 
            FROM (
                SELECT COUNT(*) AS purchase_count 
                FROM customer 
                JOIN web_sales ON ws_bill_customer_sk = c_customer_sk 
                GROUP BY c_customer_sk
            ) AS subquery
        )
),
CustomerSales AS (
    SELECT 
        cb.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent,
        AVG(ws.ws_sales_price) AS avg_spent,
        (SELECT COUNT(DISTINCT wr_order_number) FROM web_returns WHERE wr_returning_customer_sk = cb.c_customer_sk) AS return_count,
        STRING_AGG(DISTINCT wg.wg_name, ', ') AS preferred_genres
    FROM 
        FrequentBuyers fb
    JOIN 
        customer cb ON cb.c_customer_sk = fb.c_customer_sk
    JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = cb.c_customer_sk
    LEFT JOIN 
        (SELECT wp_customer_sk, wp_name AS wg_name FROM web_page) wg ON wg.wp_customer_sk = cb.c_customer_sk
    GROUP BY 
        cb.c_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_spent,
    cs.avg_spent,
    cs.return_count,
    CASE 
        WHEN cs.return_count IS NULL THEN 'No Returns' 
        ELSE 'Returns Present' 
    END AS return_status,
    CASE 
        WHEN cs.total_spent > 1000 THEN 'High Value' 
        WHEN cs.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    CASE 
        WHEN cs.return_count IS NOT NULL AND cs.return_count > 0 THEN 'Frequent Liar'
        ELSE 'Honest Buyer'
    END AS buyer_type
FROM 
    CustomerSales cs
INNER JOIN 
    RecentSales rs ON cs.c_customer_sk = rs.ws_item_sk
WHERE 
    rs.sale_rank < 10
ORDER BY 
    cs.total_spent DESC;
