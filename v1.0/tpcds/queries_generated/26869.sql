
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_customer_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT CASE WHEN wr.wr_order_number IS NOT NULL THEN wr.wr_item_sk END) AS web_returned_items,
    COUNT(DISTINCT CASE WHEN sr.sr_ticket_number IS NOT NULL THEN sr.sr_item_sk END) AS store_returned_items,
    SUM(wr.wr_return_amt) AS total_web_returned_amount,
    SUM(sr.sr_return_amt) AS total_store_returned_amount,
    (SELECT COUNT(*) 
     FROM web_page wp 
     WHERE wp.wp_access_date_sk IN (
         SELECT DISTINCT wr.wr_returned_date_sk 
         FROM web_returns wr 
         WHERE wr.wr_returning_customer_sk = c.c_customer_sk)) AS unique_web_page_accessed
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_web_returned_amount DESC, total_store_returned_amount DESC
LIMIT 100;
