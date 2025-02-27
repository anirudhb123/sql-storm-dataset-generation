
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ca.ca_city IS NOT NULL
        AND (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
        AND ws.ws_net_profit IS NOT NULL
),
TopProfits AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_profit,
        COUNT(DISTINCT rs.ws_order_number) AS order_count,
        MAX(rs.ws_net_profit) AS max_profit
    FROM 
        RankedSales rs
    WHERE
        rs.profit_rank <= 10
    GROUP BY 
        rs.ws_item_sk
),
ProfitableCities AS (
    SELECT
        ca.ca_city,
        COUNT(DISTINCT tp.ws_item_sk) AS item_count,
        AVG(tp.total_profit) AS avg_profit
    FROM
        TopProfits tp
    JOIN
        web_sales ws ON tp.ws_item_sk = ws.ws_item_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
),
FinalResult AS (
    SELECT
        pc.ca_city,
        pc.item_count,
        pc.avg_profit,
        CASE 
            WHEN pc.avg_profit IS NULL THEN 'UNDETERMINED'
            WHEN pc.avg_profit > 1000 THEN 'HIGH PROFIT CITY'
            WHEN pc.avg_profit BETWEEN 500 AND 1000 THEN 'MEDIUM PROFIT CITY'
            ELSE 'LOW PROFIT CITY'
        END AS profit_category
    FROM 
        ProfitableCities pc
)
SELECT 
    fr.ca_city,
    fr.item_count,
    fr.avg_profit,
    fr.profit_category,
    COALESCE((
        SELECT STRING_AGG(DISTINCT cd.cd_marital_status || ': ' || COUNT(*))
        FROM customer_demographics cd 
        JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk 
        WHERE cd.cd_gender = 'F' 
        AND c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_city = fr.ca_city)
    ), 'No data') AS female_demographics
FROM 
    FinalResult fr
ORDER BY 
    fr.avg_profit DESC, fr.ca_city ASC
LIMIT 100;
