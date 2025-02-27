
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_week_seq IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
), 
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(cs.cs_order_number) AS order_count,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) FILTER (WHERE cs.cs_sales_price > 100) AS high_value_orders
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.order_count,
    ci.avg_profit,
    COALESCE(r.total_sold, 0) AS total_sold,
    (SELECT COUNT(*) 
     FROM store s
     WHERE s.s_state = 'CA') AS california_stores,
    CASE 
        WHEN ci.order_count > 5 THEN 'Frequent Buyer'
        ELSE 'Occasional Buyer' 
    END AS buyer_category
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedSales r ON ci.c_customer_sk = (SELECT sr_returning_customer_sk 
                                          FROM store_returns 
                                          WHERE sr_return_quantity > 0 
                                          ORDER BY sr_return_date_sk DESC LIMIT 1)
WHERE 
    ci.avg_profit IS NOT NULL
    AND (ci.high_value_orders > 2 OR ci.order_count = 0)
ORDER BY 
    ci.avg_profit DESC, 
    ci.c_customer_sk ASC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM customer) * 0.1; 
