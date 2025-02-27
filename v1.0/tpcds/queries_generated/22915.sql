
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        s.ss_ticket_number,
        ss.ss_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ss.ss_sold_date_sk DESC) AS rank
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk > (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
),
TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_fee) AS total_return_fee
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_web_returned_quantity
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, 
        wr_returning_customer_sk
)
SELECT 
    r.c_customer_id,
    COALESCE(SUM(CASE WHEN rs.rank = 1 THEN rs.ss_ext_sales_price END), 0) AS latest_sale_amount,
    COALESCE(SUM(tr.total_returned_quantity), 0) AS total_store_returned_quantity,
    COALESCE(COUNT(DISTINCT cr.wr_returned_date_sk), 0) AS total_web_return_days,
    CASE 
        WHEN COALESCE(SUM(tr.total_returned_quantity), 0) > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    RankedSales rs
LEFT JOIN 
    TotalReturns tr ON rs.ss_ticket_number = tr.sr_ticket_number
LEFT JOIN 
    CustomerReturns cr ON rs.c_customer_id = cr.wr_returning_customer_sk
LEFT JOIN 
    customer r ON r.c_customer_id = rs.c_customer_id
WHERE 
    r.c_birth_year IS NULL OR r.c_birth_year > 1990
GROUP BY 
    r.c_customer_id
HAVING 
    latest_sale_amount > 100 OR COUNT(DISTINCT rs.ss_ticket_number) > 5
ORDER BY 
    latest_sale_amount DESC 
LIMIT 10;
