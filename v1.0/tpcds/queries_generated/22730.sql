
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold,
        LAG(ws.ws_sales_price) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number) AS previous_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_sr.returning_customer_sk,
        SUM(COALESCE(sr.return_net_loss, 0)) AS total_return_loss,
        COUNT(*) AS total_returns
    FROM 
        store_returns sr
    LEFT JOIN 
        RankedSales rs ON sr.sr_item_sk = rs.ws_item_sk
    WHERE 
        rs.price_rank = 1
    GROUP BY 
        sr.returning_customer_sk
    HAVING 
        COUNT(*) > 5
),
CustomerDemo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        IFNULL(ca.ca_state, 'Unknown') AS state
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregateSales AS (
    SELECT 
        SUM(ws.ws_net_profit) AS total_profit,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cl_state
    FROM 
        web_sales ws
    JOIN 
        CustomerDemo cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.state
    HAVING 
        SUM(ws.ws_net_profit) > 10000
)
SELECT 
    ads.cd_demo_sk,
    ads.cd_gender,
    ads.state,
    CASE 
        WHEN cr.total_return_loss IS NULL THEN 'No Returns'
        ELSE 'Has Returns'
    END AS return_status,
    ads.total_profit
FROM 
    AggregateSales ads
LEFT JOIN 
    CustomerReturns cr ON ads.cd_demo_sk = cr.returning_customer_sk
WHERE 
    ads.cd_gender = 'F' AND 
    ads.total_profit > (SELECT AVG(total_profit) FROM AggregateSales) 
ORDER BY 
    ads.total_profit DESC
FETCH FIRST 10 ROWS ONLY;
