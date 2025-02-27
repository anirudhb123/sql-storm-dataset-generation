
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_order_number, 
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_ext_sales_price DESC) AS SalesRank
    FROM web_sales ws
    WHERE ws_sold_date_sk BETWEEN 2451000 AND 2452000
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd_demo_sk,
        c_first_name,
        c_last_name,
        COALESCE(cd_gender, 'Unknown') AS gender,
        SUM(COALESCE(ws_ext_sales_price, 0)) AS total_sales
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, cd_demo_sk, c_first_name, c_last_name, cd_gender
),
SalesWithDiscounts AS (
    SELECT 
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_ext_discount_amt,
        (ss.ss_sales_price - ss.ss_ext_discount_amt) AS net_sales_price
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk > 2451000
),
WindowedReturns AS (
    SELECT 
        cr.cr_order_number,
        SUM(cr.cr_return_quantity * cr.cr_return_amt) OVER (PARTITION BY cr.cr_order_number) AS total_return_amt,
        SUM(cr.cr_return_quantity) OVER (PARTITION BY cr.cr_order_number) AS total_return_qty
    FROM catalog_returns cr
),
FinalReport AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        COALESCE(CD.gender, 'Not Provided') AS customer_gender,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales,
        COALESCE(SUM(sr_cr.return_amt), 0) AS total_catalog_returns,
        CASE 
            WHEN COUNT(DISTINCT ws.ws_order_number) > 3 THEN 'Frequent Buyer'
            ELSE 'Occasional Buyer'
        END AS buying_behavior,
        rs.SalesRank
    FROM CustomerDetails cd
    LEFT JOIN web_sales ws ON cd.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN WindowedReturns sr_cr ON ws.ws_order_number = sr_cr.cr_order_number
    LEFT JOIN RankedSales rs ON rs.web_site_sk = ws.ws_web_site_sk
    WHERE cd.total_sales > 1000
    GROUP BY cd.c_first_name, cd.c_last_name, CD.gender, rs.SalesRank
)
SELECT 
    f.*,
    (SELECT COUNT(*) 
     FROM customer c2 
     WHERE c2.c_birth_year < 1990 AND c2.c_preferred_cust_flag = 'Y') AS older_preferred_customers,
    (
        SELECT AVG(wp.wp_max_ad_count)
        FROM web_page wp
        JOIN web_sales ws2 ON wp.wp_web_page_sk = ws2.ws_web_page_sk
        WHERE ws2.ws_sales_price > 50
    ) AS average_ad_count
FROM FinalReport f
WHERE f.SalesRank <= 5
ORDER BY f.total_sales DESC, f.customer_gender, f.c_first_name;
