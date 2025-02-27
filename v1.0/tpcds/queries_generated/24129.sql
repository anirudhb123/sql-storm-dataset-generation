
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_ship_date_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
        AND ws.ws_sales_price IS NOT NULL
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
    HAVING 
        SUM(sr_return_quantity) > 0
),
ItemInfo AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(MAX(cs.cs_sales_price), 0) AS max_catalog_price
    FROM 
        item i
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT cr.wr_order_number) AS total_web_returns,
    AVG(cr.wr_return_amt_inc_tax) AS avg_web_return_value,
    (SELECT 
        COUNT(DISTINCT c.c_customer_sk)
     FROM 
        customer c
     WHERE 
        c.c_preferred_cust_flag = 'Y' 
        AND c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_credit_rating = 'Good')) AS good_customer_count
FROM 
    RankedSales rs
INNER JOIN 
    web_sales ws ON rs.ws_order_number = ws.ws_order_number
LEFT JOIN 
    CustomerReturns cr ON ws.ws_ship_customer_sk = cr.sr_returning_customer_sk
LEFT JOIN 
    customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
LEFT JOIN 
    ItemInfo ii ON ws.ws_item_sk = ii.i_item_sk
WHERE 
    (rs.PriceRank = 1 OR rs.PriceRank IS NULL)
    AND ca.ca_state = 'CA'
    AND (ws.ws_sales_price > 100.00 OR ws.ws_sales_price IS NULL)
GROUP BY 
    ca.ca_city
HAVING 
    SUM(ws.ws_net_profit) > (SELECT AVG(ws_net_profit) FROM web_sales WHERE ws_ship_date_sk > 10000)
ORDER BY 
    total_net_profit DESC;
