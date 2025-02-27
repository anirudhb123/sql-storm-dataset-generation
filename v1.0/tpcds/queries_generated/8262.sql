
WITH SalesData AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_sales_price) AS avg_sales_price,
        SUM(CASE WHEN cs.cs_sold_date_sk BETWEEN 20220101 AND 20221231 THEN cs.cs_net_profit ELSE 0 END) AS yearly_net_profit
    FROM 
        catalog_sales cs
    JOIN 
        item i ON cs.cs_item_sk = i.i_item_sk
    JOIN 
        store s ON cs.cs_ship_mode_sk = s.s_store_sk
    WHERE 
        i.i_current_price > 50.00
    GROUP BY 
        cs.cs_item_sk
),
CustomerData AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY 
        cd.cd_demo_sk
)
SELECT 
    sd.cs_item_sk,
    sd.total_quantity,
    sd.total_net_profit,
    sd.avg_sales_price,
    cd.total_customers,
    cd.avg_purchase_estimate 
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON cd.cd_demo_sk = (SELECT cd_demo_sk FROM customer WHERE c_customer_sk = sd.cs_item_sk LIMIT 1)
ORDER BY 
    sd.total_net_profit DESC
LIMIT 10;
