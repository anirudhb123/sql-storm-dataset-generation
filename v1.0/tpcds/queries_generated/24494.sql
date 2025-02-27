
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_ext_sales_price DESC) AS rnk
    FROM
        web_sales ws
    INNER JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2022 AND
        (dd.d_moy = 12 OR dd.d_moy = 1)
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_credit_rating, cd.cd_purchase_estimate
    HAVING
        SUM(ws.ws_ext_sales_price) > 10000
),
SalesInsights AS (
    SELECT
        hvc.c_customer_id,
        RANK() OVER (ORDER BY hvc.total_sales DESC) AS sales_rank,
        rws.web_site_sk,
        rws.ws_order_number,
        rws.ws_quantity,
        rws.ws_sales_price
    FROM 
        HighValueCustomers hvc
    JOIN 
        RankedSales rws ON hvc.total_sales BETWEEN 5000 AND 50000
)
SELECT 
    si.c_customer_id,
    si.sales_rank,
    si.web_site_sk,
    si.ws_order_number,
    SUM(si.ws_sales_price) OVER (PARTITION BY si.c_customer_id ORDER BY si.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
    COALESCE(MAX(NULLIF(si.ws_quantity, 0)), 1) AS effective_quantity
FROM 
    SalesInsights si
WHERE 
    si.sales_rank <= 10
ORDER BY 
    si.sales_rank, si.c_customer_id;
