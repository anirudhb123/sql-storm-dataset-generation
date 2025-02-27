
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
    AND 
        ws.ws_sold_date_sk = (
            SELECT MAX(d.d_date_sk) 
            FROM date_dim d 
            WHERE d.d_year = 2023
        )
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        (
            SELECT SUM(ws.ws_sales_price) 
            FROM web_sales ws 
            WHERE 
                ws.ws_item_sk = rs.ws_item_sk 
                AND ws.ws_order_number <> rs.ws_order_number
        ) AS total_sales_other_orders
    FROM 
        RankedSales rs
    WHERE 
        rs.rank = 1
),
AddressSummary AS (
    SELECT 
        c.c_current_addr_sk,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_current_addr_sk
)
SELECT 
    fa.ws_item_sk,
    fa.ws_order_number,
    fa.ws_sales_price,
    fa.total_sales_other_orders,
    asum.unique_customers,
    asum.avg_purchase_estimate,
    COALESCE(ROUND(fa.ws_sales_price / NULLIF(asum.avg_purchase_estimate, 0), 2), 'N/A') AS price_to_avg_purchase_ratio
FROM 
    FilteredSales fa
LEFT JOIN 
    AddressSummary asum ON fa.ws_item_sk = asum.c_current_addr_sk
WHERE 
    fa.total_sales_other_orders > 1000
    OR fa.ws_sales_price > (
        SELECT AVG(ws.ws_sales_price)
        FROM web_sales ws 
        WHERE ws.ws_item_sk = fa.ws_item_sk
    )
ORDER BY 
    fa.ws_sales_price DESC, 
    asum.unique_customers DESC
LIMIT 100;
