
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.bill_cdemo_sk,
        COUNT(*) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.bill_customer_sk, ws.bill_cdemo_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_customer_id IS NOT NULL 
        AND cd.cd_gender = 'F'
),
HighValueCustomers AS (
    SELECT 
        r.bill_customer_sk,
        r.total_orders,
        r.total_profit,
        d.cd_gender,
        d.cd_marital_status
    FROM 
        RankedSales r
    JOIN 
        CustomerDemographics d ON r.bill_cdemo_sk = d.cd_demo_sk
    WHERE 
        r.profit_rank <= 10
        AND r.total_orders > (SELECT AVG(total_orders) FROM RankedSales)
)

SELECT 
    COALESCE(ca.ca_city, 'Unknown') AS city,
    SUM(hv.total_profit) AS total_profit,
    COUNT(DISTINCT hv.bill_customer_sk) AS customer_count,
    AVG(hv.total_orders) AS avg_orders_per_customer
FROM 
    HighValueCustomers hv
LEFT JOIN 
    customer_address ca ON hv.bill_customer_sk = ca.ca_address_sk
GROUP BY 
    ca.ca_city
HAVING 
    SUM(hv.total_profit) > 10000
ORDER BY 
    total_profit DESC
LIMIT 5;
