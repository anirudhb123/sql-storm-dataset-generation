
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sold_date_sk DESC) as ranking,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.web_site_sk) as total_quantity
    FROM 
        web_sales AS ws
    WHERE 
        ws.ws_net_paid > 0
        AND ws.ws_shipping_cost IS NOT NULL
),
SalesData AS (
    SELECT 
        r.web_site_sk,
        r.web_sales_price,
        r.total_quantity,
        CASE 
            WHEN r.total_quantity > 100 THEN 'High Volume'
            WHEN r.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category,
        COALESCE(ROUND(AVG(r.web_sales_price), 2), 0) AS avg_price
    FROM 
        RankedSales AS r
    WHERE 
        r.ranking <= 10
    GROUP BY 
        r.web_site_sk, r.web_sales_price, r.total_quantity
),
AggregateSales AS (
    SELECT 
        sd.volume_category,
        SUM(sd.total_quantity) AS category_total,
        COUNT(*) AS site_count,
        SUM(sd.avg_price) AS total_avg_price
    FROM 
        SalesData AS sd
    GROUP BY 
        sd.volume_category
)
SELECT 
    a.volume_category,
    a.category_total,
    a.site_count,
    a.total_avg_price,
    CASE 
        WHEN a.category_total IS NULL THEN 'No Transactions'
        ELSE 'Transactions Exist'
    END AS transaction_status,
    STRING_AGG(DISTINCT CASE WHEN a.category_total IS NOT NULL THEN a.volume_category END, ', ') AS distinct_volumes
FROM 
    AggregateSales AS a
LEFT JOIN 
    customer_demographics AS cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer AS c WHERE c.c_customer_sk = (SELECT MIN(c2.c_customer_sk) FROM customer AS c2 WHERE c2.c_current_addr_sk IS NOT NULL))
WHERE 
    cd.cd_gender IS NOT NULL
    AND (cd.cd_marital_status = 'S' OR cd.cd_marital_status IS NULL)
GROUP BY 
    a.volume_category, a.category_total, a.site_count, a.total_avg_price
HAVING 
    a.category_total IS NOT NULL OR a.volume_category IS NOT NULL
ORDER BY 
    a.category_total DESC, a.site_count ASC;
