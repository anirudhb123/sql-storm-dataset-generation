
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
HighProfitItems AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_quantity,
        rs.total_net_profit,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.profit_rank <= 10
), 
SalesDetails AS (
    SELECT 
        hpi.ws_item_sk,
        hpi.total_quantity,
        hpi.total_net_profit,
        COALESCE((SELECT SUM(ws_ext_discount_amt) FROM web_sales ws WHERE ws.ws_item_sk = hpi.ws_item_sk), 0) AS total_discount,
        COALESCE((SELECT COUNT(DISTINCT ws_bill_customer_sk) FROM web_sales ws WHERE ws.ws_item_sk = hpi.ws_item_sk), 0) AS distinct_customers
    FROM 
        HighProfitItems hpi
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_net_profit,
    sd.total_discount,
    sd.distinct_customers,
    (sd.total_net_profit - sd.total_discount) AS net_profit_after_discount,
    CASE 
        WHEN sd.distinct_customers > 0 THEN (sd.total_net_profit / sd.distinct_customers)
        ELSE NULL 
    END AS avg_profit_per_customer
FROM 
    SalesDetails sd
LEFT JOIN 
    customer_demographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = (SELECT MIN(ws_bill_customer_sk) FROM web_sales ws WHERE ws.ws_item_sk = sd.ws_item_sk))
WHERE 
    cd.cd_gender = 'F' AND 
    cd.cd_credit_rating = 'Good'
ORDER BY 
    net_profit_after_discount DESC;
