
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023
    )
),
FilteredSales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_sold_date_sk,
        rs.ws_sales_price,
        COALESCE(NULLIF(rs.ws_sales_price, 0), NULL) AS safe_sales_price
    FROM RankedSales rs
    WHERE rs.rank_sales <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FinalSales AS (
    SELECT 
        fs.web_site_sk,
        fs.ws_order_number,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        fs.safe_sales_price,
        CASE 
            WHEN fs.safe_sales_price IS NULL THEN 'Price not available'
            ELSE CAST(fs.safe_sales_price AS VARCHAR(10))
        END AS sales_price_info
    FROM FilteredSales fs
    LEFT JOIN CustomerDetails cd ON fs.web_site_sk = cd.c_customer_sk
)
SELECT 
    f.web_site_sk,
    f.ws_order_number,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    f.safe_sales_price,
    f.sales_price_info,
    COUNT(f.ws_order_number) OVER (PARTITION BY f.cd_gender ORDER BY f.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS count_by_gender,
    CASE 
        WHEN f.cd_marital_status = 'M' THEN 'Married'
        WHEN f.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS marital_status
FROM FinalSales f
WHERE EXISTS (
    SELECT 1 
    FROM store s 
    WHERE s.s_store_sk = 100 
    AND f.web_site_sk = s.s_company_id
)
ORDER BY f.ws_order_number DESC;
