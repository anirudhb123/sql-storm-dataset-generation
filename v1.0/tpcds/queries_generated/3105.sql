
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '90 days')
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_income_band_sk
),
SalesAndReturns AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        COALESCE(sr.sr_return_quantity, 0) AS returned_quantity,
        (ws.ws_quantity - COALESCE(sr.sr_return_quantity, 0)) AS net_quantity
    FROM 
        web_sales ws
    LEFT JOIN 
        store_returns sr ON ws.ws_order_number = sr.sr_ticket_number AND ws.ws_item_sk = sr.sr_item_sk
),
FinalSummary AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        SUM(COALESCE(sar.net_quantity, 0)) AS total_net_quantity,
        SUM(sar.returned_quantity) AS total_returned_quantity,
        AVG(rp.ws_net_profit) AS average_profit,
        COUNT(DISTINCT rs.ws_order_number) AS unique_orders
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesAndReturns sar ON ci.order_count > 0 -- only customers with orders
    LEFT JOIN 
        RankedSales rp ON rp.ws_order_number = sar.ws_order_number
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name
)
SELECT 
    fs.c_customer_sk,
    fs.c_first_name,
    fs.c_last_name,
    fs.total_net_quantity,
    fs.total_returned_quantity,
    fs.average_profit,
    fs.unique_orders
FROM 
    FinalSummary fs
WHERE 
    fs.total_net_quantity > 100
ORDER BY 
    fs.average_profit DESC, fs.total_net_quantity DESC;
