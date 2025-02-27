
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        COUNT(DISTINCT ws.ws_bill_customer_sk) OVER (PARTITION BY ws.ws_item_sk) AS unique_customers
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
CustomerAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
CombinedAnalysis AS (
    SELECT 
        cs.cd_gender,
        cs.cd_marital_status,
        rws.ws_item_sk,
        rws.ws_order_number,
        rws.ws_net_profit,
        rws.total_quantity,
        cs.total_profit,
        cs.customer_count,
        cs.avg_purchase_estimate
    FROM 
        RankedSales rws
    JOIN 
        CustomerAnalysis cs ON rws.rank_profit <= 5
    WHERE 
        (cs.avg_purchase_estimate > (SELECT AVG(cd.cd_purchase_estimate) FROM customer_demographics cd WHERE cd.cd_gender = cs.cd_gender))
        OR (rws.ws_net_profit IS NULL)
),
FinalResults AS (
    SELECT 
        ca.cd_gender,
        ca.cd_marital_status,
        COUNT(DISTINCT ca.ws_item_sk) AS items_sold,
        SUM(COALESCE(ca.ws_net_profit, 0)) AS total_sales,
        AVG(ca.avg_purchase_estimate) AS average_estimates,
        COUNT(*) FILTER (WHERE ca.total_quantity > 100) AS high_volume_sales
    FROM 
        CombinedAnalysis ca
    GROUP BY 
        ca.cd_gender, ca.cd_marital_status
)
SELECT 
    f.cd_gender,
    f.cd_marital_status,
    f.items_sold,
    f.total_sales,
    f.average_estimates,
    f.high_volume_sales
FROM 
    FinalResults f
WHERE 
    f.total_sales > (SELECT AVG(total_sales) FROM FinalResults)
ORDER BY 
    f.total_sales DESC, 
    f.items_sold ASC
LIMIT 10;
