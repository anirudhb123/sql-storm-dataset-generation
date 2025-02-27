
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        ws_quantity,
        ws_net_paid,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)

    UNION ALL

    SELECT 
        ws_sold_date_sk,
        ws_item_sk, 
        ws_quantity,
        ws_net_paid,
        level + 1
    FROM web_sales
    JOIN SalesCTE ON web_sales.ws_sold_date_sk = SalesCTE.ws_sold_date_sk - 1
)

SELECT 
    C.c_customer_id,
    SUM(S.ws_quantity) AS total_quantity,
    AVG(S.ws_net_paid) AS avg_net_paid,
    COUNT(DISTINCT S.ws_item_sk) AS distinct_items,
    COALESCE(R.r_reason_desc, 'No Reason') AS return_reason,
    D.d_year,
    D.d_month_seq,
    D.d_day_name
FROM SalesCTE S
JOIN customer C ON S.ws_ship_customer_sk = C.c_customer_sk
LEFT JOIN store_returns SR ON S.ws_item_sk = SR.sr_item_sk
LEFT JOIN reason R ON SR.sr_reason_sk = R.r_reason_sk
JOIN date_dim D ON S.ws_sold_date_sk = D.d_date_sk
GROUP BY 
    C.c_customer_id, 
    D.d_year, 
    D.d_month_seq, 
    D.d_day_name,
    R.r_reason_desc
HAVING 
    total_quantity > 10 
    AND AVG(ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales) 
ORDER BY 
    total_quantity DESC, 
    avg_net_paid DESC;
