
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        ws.web_name, 
        SUM(ws.ws_ext_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT CASE WHEN wr.wr_order_number IS NOT NULL THEN wr.wr_order_number END) AS total_web_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number
    GROUP BY 
        ws.web_site_id, ws.web_name
),
CustomerData AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        CASE 
            WHEN cd.cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_segment
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateData AS (
    SELECT 
        s.web_site_id,
        SUM(sd.total_sales) AS total_sales_by_site,
        AVG(sd.total_orders) AS avg_orders_per_site,
        SUM(CASE WHEN cd.purchase_segment = 'High' THEN sd.total_sales ELSE 0 END) AS high_spender_sales
    FROM 
        SalesData sd
    LEFT JOIN 
        web_site s ON sd.web_site_id = s.web_site_id
    JOIN 
        CustomerData cd ON sd.total_orders > 0  -- Including only sites with orders
    GROUP BY 
        s.web_site_id
)
SELECT 
    ad.web_site_id,
    ad.total_sales_by_site,
    ad.avg_orders_per_site,
    CTE.total_sales AS sales_more_than_avg
FROM 
    AggregateData ad
CROSS JOIN (
    SELECT 
        AVG(total_sales_by_site) AS avg_sales
    FROM 
        AggregateData
) AS avg_cte
WHERE 
    ad.total_sales_by_site > avg_cte.avg_sales
ORDER BY 
    ad.total_sales_by_site DESC
LIMIT 10;
