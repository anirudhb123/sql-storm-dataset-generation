
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        ws_quick.date AS sold_date,
        SUM(ws.net_paid_inc_tax) AS total_net_sales,
        row_number() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid_inc_tax) DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY SUM(ws.net_paid_inc_tax)) AS sales_density
    FROM 
        web_sales ws
    JOIN 
        date_dim ws_quick ON ws.ws_sold_date_sk = ws_quick.d_date_sk
    WHERE 
        ws.bill_customer_sk IS NOT NULL AND 
        ws.ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type LIKE 'Express%')
    GROUP BY 
        ws.bill_customer_sk, ws.item_sk, ws_quick.date
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status
        END AS marital_status,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT 
    ci.c_customer_id,
    ci.marital_status,
    COALESCE(rs.total_net_sales, 0) AS total_sales,
    CASE 
        WHEN ci.rnk <= 3 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedSales rs ON ci.c_customer_id = CAST(rs.bill_customer_sk AS char(16))
WHERE 
    ci.marital_status IN ('M', 'S') OR ci.marital_status IS NULL
ORDER BY 
    total_sales DESC, ci.c_customer_id
FETCH FIRST 50 ROWS ONLY;

SELECT 
    wp.wp_url, 
    COUNT(DISTINCT wr.wr_order_number) AS return_count,
    AVG(wr.wr_return_amt) AS avg_return_amount
FROM 
    web_page wp
LEFT JOIN 
    web_returns wr ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE
    wp.wp_creation_date_sk IS NOT NULL 
    AND wp.wp_autogen_flag = 'Y'
GROUP BY 
    wp.wp_url
HAVING 
    COUNT(DISTINCT wr.wr_order_number) > 5
ORDER BY 
    return_count DESC
UNION
SELECT 
    'Total Returns' AS wp_url,
    COUNT(DISTINCT wr.wr_order_number) AS return_count,
    AVG(wr.wr_return_amt) AS avg_return_amount
FROM 
    web_returns wr
WHERE 
    wr.wr_return_amt > 0;
