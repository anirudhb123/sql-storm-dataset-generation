
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COALESCE(cd.cd_dep_count, 0) AS dependents,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_dep_count
), 
ItemReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    ca.ca_address_id,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    SUM(CASE WHEN cs.total_orders > 0 THEN 1 ELSE 0 END) AS active_customers,
    SUM(COALESCE(ir.total_returned, 0)) AS total_returns,
    AVG(cs.total_profit) AS avg_profit_per_customer,
    STRING_AGG(DISTINCT cd.cd_gender) AS unique_genders,
    CAST(NULLIF(RANK() OVER (ORDER BY SUM(ws.ws_net_profit)), 0) AS VARCHAR) AS revenue_rank
FROM 
    customer_address ca
LEFT JOIN 
    CustomerStats cs ON ca.ca_address_sk = cs.c_customer_sk
LEFT JOIN 
    RankedSales rs ON cs.c_customer_sk = rs.ws_item_sk
LEFT JOIN 
    ItemReturns ir ON rs.ws_item_sk = ir.sr_item_sk
WHERE 
    ca.ca_city IS NOT NULL 
    AND ca.ca_state = 'CA'
GROUP BY 
    ca.ca_address_id
HAVING 
    COUNT(DISTINCT cs.c_customer_sk) > 10 
    AND SUM(COALESCE(ir.total_returned, 0)) < 5
ORDER BY 
    avg_profit_per_customer DESC NULLS LAST;
