
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_net_loss,
        ROW_NUMBER() OVER(PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
TopReturns AS (
    SELECT 
        r.sr_returned_date_sk,
        r.sr_item_sk,
        r.sr_return_quantity,
        r.sr_return_amt,
        r.sr_net_loss,
        i.i_item_desc,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        SUM(r.sr_return_quantity) OVER(PARTITION BY r.sr_item_sk) AS total_return_quantity
    FROM 
        RankedReturns r
    JOIN 
        item i ON r.sr_item_sk = i.i_item_sk
    JOIN 
        customer c ON r.sr_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        r.rn = 1
),
Summary AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(tr.sr_return_amt) AS total_return_amt,
        SUM(tr.sr_net_loss) AS total_net_loss,
        AVG(tr.total_return_quantity) AS avg_return_quantity
    FROM 
        TopReturns tr
    JOIN 
        customer_address ca ON tr.sr_returned_date_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
)
SELECT 
    s.ca_city,
    s.unique_customers,
    s.total_return_amt,
    s.total_net_loss,
    s.avg_return_quantity,
    d.d_date AS return_date
FROM 
    Summary s
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE))
ORDER BY 
    s.total_return_amt DESC
LIMIT 10;
