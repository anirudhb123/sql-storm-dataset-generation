
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price) AS sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 1 AND 365
),
AggregateSales AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_sales_price) AS total_sales_price,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT rs.ws_item_sk) AS item_count
    FROM 
        RankedSales rs
    WHERE 
        rs.profit_rank = 1
    GROUP BY 
        rs.ws_order_number
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        COALESCE(cd.cd_purchase_estimate, 0) AS adjusted_purchase_estimate
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        cs.ws_order_number,
        cs.total_sales_price,
        cs.total_net_profit,
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.adjusted_purchase_estimate,
        CASE 
            WHEN cs.item_count > 10 THEN 'High Volume'
            WHEN cs.item_count BETWEEN 5 AND 10 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM 
        AggregateSales cs
    LEFT JOIN 
        CustomerDetails cd ON cd.c_customer_sk = (
            SELECT c.c_customer_sk 
            FROM web_sales ws 
            JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
            WHERE ws.ws_order_number = cs.ws_order_number 
            LIMIT 1
        )
)
SELECT 
    fr.ws_order_number,
    fr.total_sales_price,
    fr.total_net_profit,
    fr.c_customer_id,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.adjusted_purchase_estimate,
    fr.volume_category,
    CASE 
        WHEN fr.total_net_profit IS NULL THEN 'No Profit'
        WHEN fr.total_net_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    FinalReport fr
WHERE 
    fr.volume_category = 'High Volume'
ORDER BY 
    fr.total_sales_price DESC
LIMIT 100 OFFSET 50;
