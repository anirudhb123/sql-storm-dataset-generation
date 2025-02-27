
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rn,
        CASE 
            WHEN ws_sales_price IS NULL THEN 'Price Not Available'
            WHEN ws_sales_price < 0 THEN 'Negative Price Detected'
            ELSE 'Valid Price'
        END AS price_status
    FROM web_sales
    WHERE YEAR(CURRENT_DATE) - YEAR(ws_sold_date_sk) <= 2
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
    HAVING SUM(ws_sales_price) IS NOT NULL
), 
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price) AS total_sales,
        RANK() OVER (ORDER BY SUM(rs.ws_sales_price) DESC) AS sales_rank
    FROM RankedSales rs
    WHERE rs.rn = 1 -- Get only the highest priced sales
    GROUP BY rs.ws_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.total_orders,
    cs.total_spent,
    ts.total_sales,
    ts.sales_rank,
    CASE
        WHEN cs.total_orders > 10 THEN 'Frequent Buyer'
        WHEN cs.total_orders BETWEEN 5 AND 10 THEN 'Moderate Buyer'
        ELSE 'Occasional Buyer'
    END AS customer_category,
    STRING_AGG(DISTINCT ws.ws_item_sk) AS purchased_items
FROM CustomerStats cs
LEFT JOIN TopSales ts ON cs.c_customer_sk = ts.ws_item_sk
JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY cs.c_customer_sk, cs.total_orders, cs.total_spent, ts.total_sales, ts.sales_rank
HAVING SUM(ts.total_sales) IS NOT NULL OR COUNT(ws.ws_order_number) > 5
ORDER BY total_spent DESC NULLS LAST
LIMIT 100;
