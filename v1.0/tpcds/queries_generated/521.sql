
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.sold_date_sk DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY ws.net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        wd.state = 'CA' AND
        cd.cd_gender = 'F'
),
SalesSummary AS (
    SELECT 
        web_site_id,
        SUM(net_profit) AS total_profit,
        COUNT(*) AS order_count
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 5
    GROUP BY 
        web_site_id
)
SELECT 
    ss.web_site_id,
    ss.total_profit,
    ss.order_count,
    CASE 
        WHEN ss.total_profit IS NULL THEN 'No Sales'
        WHEN ss.order_count > 0 THEN 'Sales Made'
        ELSE 'Uncertain'
    END AS sales_status
FROM 
    SalesSummary ss
LEFT JOIN 
    web_site w ON ss.web_site_id = w.web_site_id
WHERE 
    (w.web_class = 'E-Commerce' OR w.web_class IS NULL)
    AND (w.web_open_date_sk <= CURRENT_DATE OR w.web_open_date_sk IS NULL)
ORDER BY 
    ss.total_profit DESC
LIMIT 10;
