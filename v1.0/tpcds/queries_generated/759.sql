
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id
),
CustomerData AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_credit_rating IS NOT NULL
),
ReturnsData AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amt
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    cs.i_item_id,
    cs.i_product_name,
    COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity_sold,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN COALESCE(SUM(ws.ws_quantity), 0) > 0 THEN 
            (COALESCE(r.total_return_amt, 0) / SUM(ws.ws_quantity)) * 100
        ELSE 0 
    END AS return_percentage,
    NULLIF(cd.cd_gender, '') AS customer_gender,
    COUNT(DISTINCT cd.c_customer_id) AS distinct_customers
FROM 
    item cs
LEFT JOIN 
    web_sales ws ON cs.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    ReturnsData r ON cs.i_item_sk = r.cr_item_sk
LEFT JOIN 
    CustomerData cd ON ws.ws_bill_customer_sk = cd.c_customer_id
WHERE 
    cs.i_current_price > 20.00
GROUP BY 
    cs.i_item_id, cs.i_product_name, r.total_returns, r.total_return_amt, cd.cd_gender
HAVING 
    SUM(ws.ws_quantity) > 50
ORDER BY 
    return_percentage DESC, total_sales DESC;
