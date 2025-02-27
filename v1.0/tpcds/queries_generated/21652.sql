
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_sales_price,
        ws.ws_order_number,
        DENSE_RANK() OVER (PARTITION BY ws.bill_cdemo_sk ORDER BY ws.net_profit DESC) AS profit_rank,
        COALESCE(NULLIF(ws_ext_discount_amt, 0), ws_ext_discount_amt) AS effective_discount,
        ws_sold_date_sk,
        ws_sold_time_sk,
        DATEADD(DAY, 7, d.d_date) AS promotion_end_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022 AND (d.d_month_seq IN (6, 7, 8) OR d.d_quarter_seq = 3) 
),
ReturnsData AS (
    SELECT 
        wr.item_sk,
        SUM(wr.return_quantity) AS total_returns,
        SUM(wr.return_amt) AS total_returned_amt,
        SUM(wr.return_tax) AS total_returned_tax,
        MAX(wr.returned_date_sk) AS last_returned_date
    FROM 
        web_returns wr
    GROUP BY 
        wr.item_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    SUM(r.total_returned_amt) AS overall_returned_amt,
    AVG(s.web_sales_price) AS average_sales_price,
    MIN(s.ws_order_number) AS first_order_number,
    MAX(s.ws_order_number) AS last_order_number,
    COUNT(DISTINCT s.ws_order_number) AS total_unique_orders,
    DENSE_RANK() OVER (ORDER BY AVG(s.ws_sales_price) DESC) AS avg_price_rank,
    CASE 
        WHEN AVG(s.ws_sales_price) IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    Customer_Address a
LEFT JOIN 
    RankedSales s ON a.ca_address_sk = s.web_site_sk
LEFT JOIN 
    ReturnsData r ON s.ws_order_number = r.item_sk
WHERE 
    a.ca_state IS NOT NULL
    AND (a.ca_city LIKE '%Spring%' OR a.ca_city LIKE '%Fall%' OR a.ca_city IS NULL)
GROUP BY 
    a.ca_city, a.ca_state
HAVING 
    SUM(r.total_returns) > 10 OR AVG(s.web_sales_price) < (SELECT AVG(ws_sales_price) FROM web_sales ws)
ORDER BY 
    overall_returned_amt DESC, 
    total_unique_orders DESC
FETCH FIRST 100 ROWS ONLY;
