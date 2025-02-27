
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COUNT(*) OVER (PARTITION BY ws.ws_item_sk) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month = EXTRACT(MONTH FROM CURRENT_DATE) 
        AND c.c_birth_day >= 15
),
AverageSales AS (
    SELECT 
        rs.ws_item_sk,
        AVG(rs.ws_sales_price) AS avg_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank < 3
    GROUP BY 
        rs.ws_item_sk
),
SalesDetail AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_sales,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price,
        CASE 
            WHEN SUM(ws.ws_sales_price) IS NULL THEN 'No Sales'
            ELSE 
                CASE 
                    WHEN SUM(ws.ws_sales_price) > 1000 THEN 'High Volume'
                    ELSE 'Low Volume'
                END 
        END AS volume_category
    FROM 
        web_sales ws
    LEFT JOIN 
        AverageSales AS avg_sales ON ws.ws_item_sk = avg_sales.ws_item_sk
    WHERE 
        (avg_sales.avg_sales_price IS NULL OR ws.ws_sales_price > avg_sales.avg_sales_price)
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    sd.ws_item_sk,
    sd.order_count,
    sd.total_sales,
    sd.max_price,
    sd.min_price,
    sd.volume_category,
    CASE 
        WHEN sd.max_price = 0 THEN NULL
        ELSE ROUND(sd.total_sales / NULLIF(sd.max_price, 0), 2)
    END AS sales_to_price_ratio,
    COALESCE(packet_pack_count.packet_count, 0) AS packet_count
FROM 
    SalesDetail sd
LEFT JOIN (
    SELECT 
        ws_item_sk,
        COUNT(*) AS packet_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_return_quantity > 0
    GROUP BY 
        wr.ws_item_sk
) AS packet_pack_count ON sd.ws_item_sk = packet_pack_count.ws_item_sk
WHERE 
    sd.order_count IS NOT NULL
ORDER BY 
    sd.total_sales DESC, 
    sales_to_price_ratio DESC
LIMIT 10;
