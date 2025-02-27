
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_moy = 10
        )
),
AggregatedSales AS (
    SELECT 
        item.i_item_id,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        item 
    LEFT JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL OR ws.ws_order_number IN (
            SELECT ws_order_number 
            FROM web_sales 
            WHERE ws_customer_sk IS NULL
        )
    GROUP BY 
        item.i_item_id
),
CustomerCounts AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    GROUP BY 
        c.c_customer_id
)
SELECT 
    a.i_item_id,
    a.total_sales,
    a.order_count,
    COALESCE(b.customer_count, 0) AS customer_count,
    COALESCE(b.max_purchase_estimate, 0) AS max_purchase_estimate
FROM 
    AggregatedSales a
FULL OUTER JOIN 
    CustomerCounts b ON a.total_sales > 1000 OR b.customer_count IS NULL
WHERE 
    a.total_sales > (SELECT AVG(total_sales) FROM AggregatedSales)
    AND EXISTS (
        SELECT 1
        FROM RankedSales r
        WHERE r.sales_rank = 1 AND r.ws_item_sk = a.i_item_sk
    )
ORDER BY 
    a.total_sales DESC, 
    b.max_purchase_estimate ASC
LIMIT 100;
