
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_date,
        CASE 
            WHEN ws.ws_sales_price IS NULL THEN 'No Price'
            WHEN ws.ws_sales_price < 0 THEN 'Negative Price'
            ELSE 'Valid Price'
        END AS price_status
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        ws.ws_sales_price BETWEEN 0 AND 100
        OR (ws.ws_sales_price IS NULL AND d.d_dow = 5)
),
FilteredSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_order_number, 
        rs.ws_net_paid,
        rs.rank_sales_price,
        rs.price_status
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_sales_price = 1
        AND rs.price_status <> 'No Price'
)
SELECT 
    fa.customer_id,
    fs.ws_item_sk,
    fs.ws_order_number,
    fs.ws_net_paid,
    COALESCE(CASE WHEN fs.ws_net_paid > 0 THEN 'Profitable' ELSE 'Not Profitable' END, 'Unknown') AS profitability_status,
    COALESCE((SELECT AVG(ws.ws_net_paid) FROM web_sales ws WHERE ws.ws_item_sk = fs.ws_item_sk), 0) AS avg_net_paid
FROM 
    FilteredSales fs
LEFT JOIN 
    (SELECT 
        DISTINCT c.c_customer_id, c.c_customer_sk
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'S'
    ) fa ON fa.c_customer_sk = fs.ws_order_number
ORDER BY 
    fs.ws_net_paid DESC NULLS LAST;
