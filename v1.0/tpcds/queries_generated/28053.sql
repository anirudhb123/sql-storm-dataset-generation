
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1) AS domain,
    COUNT(DISTINCT wr.wr_order_number) AS web_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_returns,
    SUM(CASE 
        WHEN wr.wr_return_amt > 0 THEN wr.wr_return_amt 
        ELSE 0 
    END) AS total_web_return_amount,
    SUM(CASE 
        WHEN sr.sr_return_amt > 0 THEN sr.sr_return_amt 
        ELSE 0 
    END) AS total_store_return_amount,
    STRING_AGG(DISTINCT CONCAT(wp.wp_url, ' - ', wr.wr_order_number), '; ') AS web_page_urls_returned
FROM 
    customer c
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    c.c_last_name, c.c_first_name;
