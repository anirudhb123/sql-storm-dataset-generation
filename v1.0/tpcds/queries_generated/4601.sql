
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerDetail AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    CD.c_customer_id,
    CD.c_first_name,
    CD.c_last_name,
    CD.cd_gender,
    COALESCE(RS.web_site_id, 'No Sales') AS web_site_id,
    COALESCE(RS.ws_sales_price, 0) AS last_sales_price,
    COALESCE(RS.ws_ext_sales_price, 0) AS last_ext_sales_price,
    CD.cd_purchase_estimate,
    CASE 
        WHEN CD.cd_dep_count IS NULL THEN 'No Dependents'
        WHEN CD.cd_dep_count > 0 THEN 'Has Dependents'
        ELSE 'No Dependents'
    END AS dependent_status,
    CASE 
        WHEN RS.profit_rank = 1 THEN 'Top Seller'
        ELSE 'Regular Seller'
    END AS seller_status
FROM 
    CustomerDetail CD
LEFT JOIN 
    RankedSales RS ON CD.c_customer_id = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) LIMIT 1)
WHERE 
    (CD.cd_gender = 'F' AND CD.cd_marital_status = 'M') OR (CD.cd_dep_count > 2)
ORDER BY 
    CD.c_last_name ASC, 
    CD.c_first_name ASC;
