
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_sold_date_sk
    UNION ALL
    SELECT 
        dd.d_date_sk,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_orders, 0) AS total_orders
    FROM 
        date_dim dd
    LEFT JOIN 
        SalesCTE s ON dd.d_date_sk = s.ws_sold_date_sk
    WHERE 
        dd.d_date_sk > (SELECT MIN(ws_sold_date_sk) FROM web_sales)
),
CustomerReturnData AS (
    SELECT
        cr.returning_cdemo_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(cr.cr_order_number) AS total_return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_cdemo_sk
),
CustomerInsights AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_count, 0) AS total_return_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        CustomerReturnData cr ON c.c_current_cdemo_sk = cr.returning_cdemo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
)
SELECT 
    cis.c_customer_id, 
    cis.cd_gender, 
    cis.cd_marital_status, 
    cis.cd_purchase_estimate,
    SUM(ct.total_sales) AS total_sales,
    SUM(ct.total_orders) AS total_orders,
    cis.total_return_amount,
    cis.total_return_count,
    (SUM(ct.total_sales) - COALESCE(cis.total_return_amount, 0)) AS net_sales
FROM 
    CustomerInsights cis
JOIN 
    SalesCTE ct ON ct.ws_sold_date_sk IS NOT NULL
GROUP BY 
    cis.c_customer_id, cis.cd_gender, cis.cd_marital_status, cis.cd_purchase_estimate, cis.total_return_amount, cis.total_return_count
HAVING 
    net_sales > 1000
ORDER BY 
    net_sales DESC;
