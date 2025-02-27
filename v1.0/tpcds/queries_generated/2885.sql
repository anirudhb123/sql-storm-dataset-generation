
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
TopWebSites AS (
    SELECT 
        r.web_site_sk,
        r.web_name
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_return_qty) AS total_returned_qty,
        SUM(wr.wr_return_amt) AS total_returned_amt
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY 
        wr.refunded_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    w.web_name,
    COALESCE(cr.total_returned_qty, 0) AS total_returns,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amount,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) AS store_sales_count,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_customer_sk = c.c_customer_sk) AS catalog_sales_count
FROM 
    customer c
JOIN 
    TopWebSites w ON c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_city = 'Seattle')
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.refunded_customer_sk
WHERE 
    NOT EXISTS (
        SELECT 1 FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk AND sr.sr_return_quantity < 0
    )
ORDER BY 
    c.c_customer_id;
