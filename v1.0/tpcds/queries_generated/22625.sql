
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopSellingItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        rs.total_quantity,
        rs.total_profit
    FROM 
        RankedSales rs
    JOIN 
        item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.rank_profit <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND (cd.cd_marital_status IS NULL OR cd.cd_marital_status != 'D')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    HAVING 
        SUM(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_bill_customer_sk = c.c_customer_sk)
),
ReturnsSummary AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_refunded
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
NetSales AS (
    SELECT 
        tsi.i_item_id,
        tsi.i_item_desc,
        tsi.total_quantity,
        tsi.total_profit,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.total_refunded, 0) AS total_refunded,
        (tsi.total_profit - COALESCE(rs.total_refunded, 0)) AS net_profit
    FROM 
        TopSellingItems tsi
    LEFT JOIN 
        ReturnsSummary rs ON tsi.i_item_id = CAST(rs.sr_item_sk AS CHAR(16))
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ni.i_item_id,
    ni.total_quantity,
    ni.net_profit
FROM 
    CustomerInfo ci
JOIN 
    NetSales ni ON ci.order_count > 10
WHERE 
    ni.net_profit > (SELECT AVG(net_profit) FROM NetSales)
ORDER BY 
    ni.net_profit DESC
LIMIT 10;
