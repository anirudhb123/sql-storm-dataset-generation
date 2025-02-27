
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IS NOT NULL
    GROUP BY
        ws.web_site_sk,
        ws.ws_order_number
),
ReturnAnalysis AS (
    SELECT
        wr.wr_web_page_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        COUNT(DISTINCT wr.wr_refunded_customer_sk) AS unique_customers
    FROM
        web_returns wr
    WHERE
        wr.wr_return_amt > 0
    GROUP BY
        wr.wr_web_page_sk
),
AddressCount AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY
        ca.ca_state
)
SELECT
    ra.web_site_sk,
    ra.ws_order_number,
    ra.total_sales,
    COALESCE(ra.total_sales - r.total_returned, ra.total_sales) AS net_sales,
    ac.total_customers,
    CASE
        WHEN ac.total_customers > 1000 THEN 'High Engagement'
        WHEN ac.total_customers BETWEEN 500 AND 1000 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS engagement_category
FROM
    RankedSales ra
LEFT JOIN
    ReturnAnalysis r ON ra.ws_order_number = r.wr_web_page_sk
LEFT JOIN
    AddressCount ac ON ra.web_site_sk = ac.ca_state
WHERE
    ra.sales_rank = 1
    AND (ac.total_customers IS NULL OR ac.total_customers >= 100)
    OR (ra.total_sales IS NULL AND r.total_returned IS NOT NULL)
ORDER BY
    net_sales DESC, 
    engagement_category ASC;
