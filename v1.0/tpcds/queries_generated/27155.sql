
WITH RankedReturns AS (
    SELECT 
        wr.web_page_sk,
        wr.return_order_number,
        wr.return_quantity,
        wr.return_amt,
        wr.return_tax,
        wr.return_amt_inc_tax,
        ROW_NUMBER() OVER (PARTITION BY wr.web_page_sk ORDER BY wr.return_amt DESC) as return_rank
    FROM 
        web_returns wr
    INNER JOIN 
        web_page wp ON wr.web_page_sk = wp.wp_web_page_sk
    WHERE 
        wp.wp_creation_date_sk IS NOT NULL 
        AND wr.return_quantity > 0
),
HighValueReturns AS (
    SELECT 
        rr.web_page_sk,
        rr.return_order_number,
        rr.return_quantity,
        rr.return_amt,
        rr.return_tax,
        rr.return_amt_inc_tax
    FROM 
        RankedReturns rr
    WHERE 
        rr.return_rank <= 10
)
SELECT 
    wp.wp_url,
    COUNT(hvr.return_order_number) AS top_return_count,
    SUM(hvr.return_amt) AS total_return_amt,
    AVG(hvr.return_quantity) AS avg_return_quantity
FROM 
    HighValueReturns hvr
INNER JOIN 
    web_page wp ON hvr.web_page_sk = wp.wp_web_page_sk
GROUP BY 
    wp.wp_url
ORDER BY 
    total_return_amt DESC;
