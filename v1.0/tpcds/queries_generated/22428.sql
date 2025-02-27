
WITH RankedReturns AS (
    SELECT 
        wr.returned_date_sk,
        wr.return_time_sk,
        wr.item_sk,
        wr.return_quantity,
        wr.return_amt,
        wr_return_customer_sk,
        wr_returned_cdemo_sk,
        ROW_NUMBER() OVER (PARTITION BY wr_return_customer_sk ORDER BY wr.return_amt DESC) AS rnk
    FROM 
        web_returns wr
    WHERE 
        wr.return_amt > 0
),
SalesAggregates AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT ws.bill_customer_sk) AS distinct_customers
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),
CustomerMetrics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependents
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    a.ca_address_sk,
    a.ca_city,
    a.ca_state,
    coalesce(r.rnk, 0) AS return_rank,
    sa.total_net_profit,
    cm.total_customers,
    cm.avg_purchase_estimate,
    cm.max_dependents,
    (CASE 
        WHEN sa.total_orders > 0 THEN sa.total_net_profit / sa.total_orders
        ELSE NULL 
     END) AS profit_per_order,
    (SELECT 
        COUNT(*) 
     FROM 
        store_sales ss 
     WHERE 
        ss.store_sk = (SELECT s_store_sk FROM store s WHERE s.city = a.ca_city AND s.state = a.ca_state)
        AND ss.sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31')
    ) AS sales_count_last_year
FROM 
    customer_address a
LEFT JOIN 
    RankedReturns r ON a.ca_address_sk = r.wr_returning_addr_sk
LEFT JOIN 
    SalesAggregates sa ON r.wr_return_customer_sk = sa.web_site_sk
LEFT JOIN 
    CustomerMetrics cm ON r.wr_returned_cdemo_sk = cm.cd_demo_sk
WHERE 
    (COALESCE(a.ca_country, '') <> '' OR a.ca_city IS NULL)
    AND (r.return_quantity IS NOT NULL OR a.ca_state IS NOT NULL)
ORDER BY 
    a.ca_city, return_rank DESC;
