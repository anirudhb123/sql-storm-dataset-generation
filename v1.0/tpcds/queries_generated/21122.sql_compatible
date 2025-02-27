
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 5 AND 8
    )
    GROUP BY ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk, 
        COUNT(cr.returning_customer_sk) AS return_count,
        SUM(cr.cr_return_amt) AS total_return_amt,
        COUNT(DISTINCT cr.cr_order_number) AS unique_returns
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk IS NOT NULL
    GROUP BY cr.returning_customer_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT s.s_store_sk) AS store_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN store s ON ca.ca_city = s.s_city AND ca.ca_state = s.s_state
    GROUP BY ca.ca_city
)
SELECT 
    a.ca_city,
    a.customer_count,
    a.store_count,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cr.total_return_amt, 0.00) AS total_returns,
    CASE 
        WHEN rs.sales_rank IS NOT NULL AND rs.sales_rank <= 3 
            THEN 'Top Performer' 
        ELSE 'Regular' 
    END AS rank_status
FROM AddressDetails a
LEFT JOIN RankedSales rs ON a.customer_count = rs.order_count
LEFT JOIN CustomerReturns cr ON a.customer_count = cr.returning_customer_sk
WHERE a.customer_count > 0 AND (cr.return_count IS NULL OR cr.return_count < 5)
ORDER BY a.ca_city, total_sales DESC, customer_count ASC;
