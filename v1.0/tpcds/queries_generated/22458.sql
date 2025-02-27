
WITH RankedSales AS (
    SELECT 
        ws.customer_sk,
        ws.item_sk,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.customer_sk ORDER BY ws.net_profit DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY ws.customer_sk ORDER BY ws.net_profit DESC) AS dense_rank,
        COUNT(*) OVER (PARTITION BY ws.customer_sk) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.net_profit IS NOT NULL 
        AND ws.sold_date_sk = (SELECT MAX(sold_date_sk) FROM web_sales)
),
CustomerDetails AS (
    SELECT 
        c.customer_sk, 
        c.email_address, 
        cd.gender,
        COALESCE(cd.marital_status, 'Unknown') AS marital_status
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
),
CustomerProfits AS (
    SELECT 
        rd.customer_sk,
        SUM(rd.net_profit) AS total_profit
    FROM 
        RankedSales rd
    GROUP BY 
        rd.customer_sk
    HAVING 
        SUM(rd.net_profit) > 1000
)
SELECT
    cd.customer_sk,
    cd.email_address,
    cd.marital_status,
    cp.total_profit,
    COUNT(DISTINCT rs.item_sk) AS unique_item_count,
    MAX(CASE WHEN rs.sales_rank = 1 THEN rs.net_profit ELSE NULL END) AS top_profit
FROM 
    CustomerDetails cd
JOIN 
    CustomerProfits cp ON cd.customer_sk = cp.customer_sk
LEFT JOIN 
    RankedSales rs ON cd.customer_sk = rs.customer_sk
WHERE 
    cd.marital_status IS NOT NULL 
    OR EXISTS (
        SELECT 1
        FROM store s
        WHERE s.store_sk = rs.item_sk
        AND s.state = 'CA'
    )
GROUP BY 
    cd.customer_sk, cd.email_address, cd.marital_status, cp.total_profit
ORDER BY 
    total_profit DESC
FETCH FIRST 10 ROWS ONLY;
