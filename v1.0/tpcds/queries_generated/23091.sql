
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_moy IN (SELECT DISTINCT d_moy FROM date_dim WHERE d_holiday = 'Y')
    )
),
FilteredRankedSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_item_sk,
        rs.ws_sales_price,
        rs.ws_net_profit
    FROM RankedSales rs
    WHERE rs.profit_rank <= 5
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(NULLIF(i.i_brand, ''), 'Unknown Brand') AS item_brand,
        CASE 
            WHEN i.i_current_price > 100 THEN 'Premium'
            WHEN i.i_current_price BETWEEN 50 AND 100 THEN 'Mid-range'
            ELSE 'Economy'
        END AS price_category
    FROM item i
)
SELECT 
    fd.web_site_sk,
    id.item_brand,
    id.i_item_desc,
    fd.ws_sales_price,
    fd.ws_net_profit,
    (CASE 
        WHEN fd.ws_net_profit IS NULL THEN 'No Profit'
        ELSE CAST(fd.ws_net_profit / NULLIF(fd.ws_sales_price, 0) AS DECIMAL(10, 2))
    END) AS profit_margin_ratio
FROM FilteredRankedSales fd
JOIN ItemDetails id ON fd.ws_item_sk = id.i_item_sk
LEFT JOIN customer c ON c.c_current_cdemo_sk IN (
    SELECT cd.cd_demo_sk
    FROM customer_demographics cd
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
)
WHERE c.c_customer_sk IS NULL OR c.c_birth_year BETWEEN 1970 AND 1990
ORDER BY fd.web_site_sk, profit_margin_ratio DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM FilteredRankedSales) / 2;
