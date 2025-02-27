
WITH RankedWebSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
),
MaxReturn AS (
    SELECT 
        sr_item_sk,
        MAX(sr_return_amt) AS max_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerReturns AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(SUM(wr_return_amt), 0) AS total_web_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_store_returns
    FROM 
        customer c
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    rws.ws_sold_date_sk,
    rws.ws_item_sk,
    rws.ws_quantity,
    rws.ws_sales_price,
    cr.c_customer_sk,
    cr.total_web_returns,
    cr.total_store_returns,
    CASE 
        WHEN cr.total_web_returns > cr.total_store_returns THEN 'Web Dominant'
        WHEN cr.total_web_returns < cr.total_store_returns THEN 'Store Dominant'
        ELSE 'Equal Returns'
    END AS return_type,
    (SELECT 
        STRING_AGG(DISTINCT ca.ca_city, ', ') 
     FROM 
        customer_address ca 
     WHERE 
        ca.ca_address_sk IN (
            SELECT 
                DISTINCT c.c_current_addr_sk 
            FROM 
                customer c 
            WHERE 
                c.c_customer_sk = cr.c_customer_sk
        )
    ) AS customer_cities,
    (SELECT 
        COUNT(DISTINCT i.i_item_id) 
     FROM 
        item i 
     JOIN 
        MaxReturn mr ON i.i_item_sk = mr.sr_item_sk 
     WHERE 
        mr.max_return_amt > 100.00
    ) AS high_return_item_count
FROM 
    RankedWebSales rws
JOIN 
    CustomerReturns cr ON rws.ws_item_sk = cr.c_customer_sk
WHERE 
    rws.rank = 1
AND 
    rws.ws_quantity > (
        SELECT 
            AVG(ws_quantity) 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = rws.ws_item_sk
    )
ORDER BY 
    rws.ws_sold_date_sk DESC, 
    cr.total_web_returns DESC;
