
WITH CustomerAggregate AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT sr.ticket_number) AS total_store_returns,
        COUNT(DISTINCT wr.order_number) AS total_web_returns,
        SUM(sr.return_quantity) AS total_store_returned_qty,
        SUM(wr.return_quantity) AS total_web_returned_qty
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
),

ItemAggregate AS (
    SELECT 
        i.i_item_sk,
        LOWER(TRIM(i.i_item_desc)) AS item_description, 
        COUNT(DISTINCT ws.order_number) AS total_web_sales,
        SUM(ws.ws_quantity) AS total_web_sold_qty,
        SUM(cs.cs_quantity) AS total_catalog_sold_qty,
        SUM(ss.ss_quantity) AS total_store_sold_qty
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),

FinalBenchmark AS (
    SELECT 
        ca.c_customer_sk,
        ia.i_item_sk,
        ia.item_description,
        ca.total_store_returns,
        ca.total_web_returns,
        ca.total_store_returned_qty,
        ca.total_web_returned_qty,
        ia.total_web_sales,
        ia.total_web_sold_qty,
        ia.total_catalog_sold_qty,
        ia.total_store_sold_qty
    FROM 
        CustomerAggregate ca
    JOIN 
        ItemAggregate ia ON (ca.total_store_returns + ca.total_web_returns > 0 AND ia.total_web_sales > 0)
)

SELECT 
    c.c_customer_id, 
    i.i_item_id, 
    i.item_description, 
    ca.total_store_returns, 
    ca.total_web_returns, 
    ca.total_store_returned_qty, 
    ca.total_web_returned_qty, 
    ia.total_web_sales, 
    ia.total_web_sold_qty, 
    ia.total_catalog_sold_qty, 
    ia.total_store_sold_qty
FROM 
    FinalBenchmark fb
JOIN 
    customer c ON fb.c_customer_sk = c.c_customer_sk
JOIN 
    item i ON fb.i_item_sk = i.i_item_sk
ORDER BY 
    ca.total_store_returns DESC, ca.total_web_returns DESC;
