
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.web_site_id
),
TopWebsites AS (
    SELECT web_site_id
    FROM RankedSales
    WHERE rank <= 5
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.cr_return_amt) AS total_return_amount,
        COUNT(cr.cr_return_quantity) AS return_count,
        MAX(cr.cr_returned_date_sk) AS last_return_date
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
),
AddressCounts AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT ca.ca_address_sk) AS distinct_addresses
    FROM customer_address ca
    GROUP BY ca.ca_country
)
SELECT 
    twi.web_site_id,
    SUM(COALESCE(cst.total_return_amount, 0)) AS total_returns,
    ac.distinct_addresses,
    ROUND(AVG(COALESCE(ws.ws_ext_sales_price - cr.cr_return_amt, 0)), 2) AS avg_net_sales
FROM TopWebsites twi
LEFT JOIN CustomerReturns cst ON cst.returning_customer_sk IN (
    SELECT c_customer_sk FROM customer WHERE c_current_addr_sk IS NOT NULL
)
LEFT JOIN web_sales ws ON twi.web_site_id = ws.ws_web_site_id
LEFT JOIN catalog_returns cr ON ws.ws_order_number = cr.cr_order_number
LEFT JOIN AddressCounts ac ON ac.ca_country = (
    SELECT ca.ca_country
    FROM customer_address ca
    WHERE ca.ca_address_sk = (
        SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_id = twi.web_site_id
    )
)
GROUP BY twi.web_site_id, ac.distinct_addresses
ORDER BY total_returns DESC, twi.web_site_id;
