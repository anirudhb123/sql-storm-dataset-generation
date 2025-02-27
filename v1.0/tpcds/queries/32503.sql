
WITH RECURSIVE CustomerCTE AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        c_current_addr_sk,
        0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_addr_sk, 
        cc.level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_current_addr_sk = cc.c_current_addr_sk
    WHERE cc.level < 3
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2021 AND 2023
    GROUP BY ws.ws_item_sk
),
CustomerSales AS (
    SELECT 
        cc.c_customer_sk,
        cc.c_first_name,
        cc.c_last_name,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(sd.average_sales_price, 0) AS average_sales_price
    FROM CustomerCTE cc
    LEFT JOIN SalesData sd ON cc.c_customer_sk = sd.ws_item_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name,
    CASE 
        WHEN cs.total_sales > 100 THEN 'High Buyer'
        WHEN cs.total_sales BETWEEN 50 AND 100 THEN 'Medium Buyer'
        ELSE 'Low Buyer' 
    END AS buyer_category,
    ROUND(cs.average_sales_price, 2) AS avg_price,
    COUNT(DISTINCT CASE WHEN zr.r_reason_desc IS NOT NULL THEN zr.r_reason_desc END) AS reasons_count
FROM CustomerSales cs
LEFT JOIN (
    SELECT 
        sr.sr_item_sk, 
        r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
) AS zr ON cs.c_customer_sk = zr.sr_item_sk
GROUP BY 
    cs.c_customer_sk, 
    cs.c_first_name, 
    cs.c_last_name, 
    cs.total_sales, 
    cs.average_sales_price
ORDER BY total_sales DESC, avg_price DESC
LIMIT 50;
