
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 5000
),
HighValueReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk > 10000
    GROUP BY cr.cr_item_sk
    HAVING SUM(cr.cr_return_amount) > 1000
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    MAX(rs.ws_sales_price) AS highest_sale,
    COALESCE(SUM(hr.return_count), 0) AS total_returns,
    CASE 
        WHEN AVG(cd.cd_purchase_estimate) > 10000 THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS customer_category,
    COUNT(DISTINCT cd.c_customer_sk) OVER () AS unique_customer_count
FROM CustomerDetails cd
LEFT JOIN RankedSales rs ON cd.c_customer_sk = rs.web_site_sk
LEFT JOIN HighValueReturns hr ON rs.ws_order_number = hr.cr_item_sk
GROUP BY cd.c_first_name, cd.c_last_name
HAVING MAX(rs.ws_sales_price) IS NOT NULL AND COUNT(DISTINCT rs.ws_order_number) > 2
ORDER BY highest_sale DESC, cd.c_last_name ASC NULLS LAST
LIMIT 10;
