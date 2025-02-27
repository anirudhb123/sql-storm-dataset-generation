
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws.ws_net_profit) AS avg_profit,
        MAX(ws.ws_sales_price) AS max_price,
        MIN(ws.ws_sales_price) AS min_price
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) 
        AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.web_site_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd.cd_purchase_estimate > 1000 THEN 1 ELSE 0 END) AS high_value_customers,
        AVG(cd.cd_dep_count) AS avg_dependent_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
ReturnsSummary AS (
    SELECT 
        sr_reason_sk,
        COUNT(sr_order_number) AS total_returns,
        SUM(COALESCE(sr_return_amt, 0)) AS total_returned_amount,
        SUM(COALESCE(sr_net_loss, 0)) AS total_net_loss
    FROM 
        store_returns sr
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY 
        sr_reason_sk
)
SELECT 
    ss.web_site_id,
    ss.total_orders,
    ss.total_revenue,
    ROUND(ss.avg_profit, 2) AS avg_profit,
    JSON_AGG(cd) AS demographics,
    JSON_AGG(rs) AS returns_summary
FROM 
    SalesSummary ss
JOIN 
    CustomerDemographics cd ON ss.total_orders > 10
LEFT JOIN 
    ReturnsSummary rs ON rs.total_returns > 0
WHERE 
    (ss.total_revenue > (SELECT AVG(total_revenue) FROM SalesSummary) 
        OR ss.total_orders = (SELECT MAX(total_orders) FROM SalesSummary))
    AND NOT EXISTS (SELECT 1 FROM store s WHERE s.s_closed_date_sk IS NOT NULL)
GROUP BY 
    ss.web_site_id
HAVING 
    COUNT(DISTINCT cd.customer_count) > 1
ORDER BY 
    ss.total_revenue DESC
LIMIT 5 OFFSET 3;
