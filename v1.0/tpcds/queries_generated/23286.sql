
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0 
        AND ws.ws_item_sk IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_purchases,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_purchases
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING 
        (COALESCE(SUM(ss.ss_quantity), 0) > 0 OR COALESCE(SUM(ws.ws_quantity), 0) > 0)
        AND COUNT(DISTINCT ss.ss_ticket_number) + COUNT(DISTINCT ws.ws_order_number) > 1
),
ReturnStats AS (
    SELECT 
        sr.return_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    WHERE 
        sr.return_customer_sk IS NOT NULL
    GROUP BY 
        sr.return_customer_sk
),
CombinedStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.total_store_purchases,
        cs.total_web_purchases,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0.00) AS total_returned_amount
    FROM 
        CustomerStats cs
    LEFT JOIN 
        ReturnStats rs ON cs.c_customer_sk = rs.return_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.cd_gender,
    SUM(CASE 
            WHEN cr.cr_item_sk IS NOT NULL THEN cr.cr_return_quantity 
            ELSE 0 END) AS total_catalog_returns,
    SUM(CASE 
            WHEN wr.wr_item_sk IS NOT NULL THEN wr.wr_return_quantity 
            ELSE 0 END) AS total_web_returns,
    SUM(cs.total_returns) AS total_combined_returns
FROM 
    CombinedStats c
LEFT JOIN 
    catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
WHERE 
    c.total_web_purchases > 1000
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, c.cd_gender
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY 
    total_combined_returns DESC
LIMIT 50;
