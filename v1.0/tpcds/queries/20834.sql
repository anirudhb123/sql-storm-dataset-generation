
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 
        AND (ws.ws_net_paid_inc_tax IS NOT NULL OR ws.ws_net_paid_inc_tax > 0)
    GROUP BY 
        ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 1000 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 1001 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender = 'F' AND 
        (cd.cd_credit_rating IS NULL OR cd.cd_credit_rating LIKE 'A%')
),
ReturnStats AS (
    SELECT 
        sr.sr_item_sk, 
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    COALESCE(ca.ca_city, 'Unknown City') AS city,
    COALESCE(c.c_customer_id, 'Unknown Customer ID') AS customer_id,
    rs.total_quantity,
    rs.total_sales,
    cd.purchase_category,
    COALESCE(rs2.total_returns, 0) AS return_count,
    COALESCE(rs2.total_return_amount, 0.00) AS total_return_amount
FROM 
    RankedSales rs
LEFT JOIN 
    ReturnStats rs2 ON rs.ws_item_sk = rs2.sr_item_sk
FULL OUTER JOIN 
    customer c ON c.c_customer_sk = (SELECT c_sub.c_customer_sk FROM customer c_sub WHERE c_sub.c_birth_year > 1980 ORDER BY RANDOM() LIMIT 1)
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    (rs.total_sales > 5000 OR (cd.purchase_category = 'Medium' AND rs.total_quantity < 100))
ORDER BY 
    rs.total_sales DESC, 
    city ASC, 
    customer_id DESC;
