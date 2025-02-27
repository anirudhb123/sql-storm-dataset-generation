
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_list_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rnk
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
),
SalesSummary AS (
    SELECT
        r.web_site_sk,
        SUM(r.ws_quantity) AS total_quantity,
        SUM(r.ws_list_price) AS total_sales,
        AVG(r.ws_list_price) AS avg_price,
        COUNT(DISTINCT r.ws_order_number) AS order_count
    FROM RankedSales r
    WHERE r.rnk <= 10
    GROUP BY r.web_site_sk
),
Demographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
)
SELECT
    s.web_site_id,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_price,
    d.cd_gender,
    d.cd_marital_status,
    d.total_profit,
    CASE 
        WHEN ss.total_sales > 100000 THEN 'High Value' 
        WHEN ss.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Value' 
        ELSE 'Low Value' 
    END AS sales_category
FROM SalesSummary ss
LEFT JOIN web_site s ON ss.web_site_sk = s.web_site_sk
JOIN Demographics d ON ss.web_site_sk % 2 = 0  -- Just an example relationship
WHERE ss.total_quantity IS NOT NULL 
    AND (ss.avg_price > 20.00 OR d.cd_marital_status IS NULL)
ORDER BY ss.total_sales DESC, d.total_profit DESC;
