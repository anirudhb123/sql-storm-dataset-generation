
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
),
TopSales AS (
    SELECT
        rs.ws_item_sk,
        rs.total_sales,
        rs.sales_rank,
        rs.order_count,
        it.i_item_desc,
        it.i_price,
        COALESCE(ci.coupon_discount, 0) AS coupon_discount
    FROM
        RankedSales rs
    JOIN
        item it ON rs.ws_item_sk = it.i_item_sk
    LEFT JOIN (
        SELECT 
            cs_item_sk, 
            SUM(cs_coupon_amt) AS coupon_discount 
        FROM 
            catalog_sales 
        WHERE 
            cs_sold_date_sk BETWEEN 20230101 AND 20231231 
        GROUP BY 
            cs_item_sk
    ) ci ON rs.ws_item_sk = ci.cs_item_sk
    WHERE 
        rs.sales_rank <= 10
),
SalesSummary AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_sales - ts.coupon_discount AS net_sales,
        ts.order_count,
        ROUND((ts.total_sales - ts.coupon_discount) / NULLIF(ts.order_count, 0), 2) AS avg_sales_per_order
    FROM 
        TopSales ts
)
SELECT 
    ss.ws_item_sk,
    ss.net_sales,
    ss.order_count,
    ss.avg_sales_per_order,
    COALESCE(cdm.cd_gender, 'Unknown') AS customer_gender,
    ca.ca_city,
    MAX(DISTINCT CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name)) AS full_address
FROM 
    SalesSummary ss
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ss.ws_item_sk
LEFT JOIN 
    customer_demographics cdm ON c.c_current_cdemo_sk = cdm.cd_demo_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ss.net_sales > (SELECT AVG(net_sales) FROM SalesSummary) 
    AND (cdm.cd_marital_status = 'M' OR cdm.cd_marital_status IS NULL)
GROUP BY 
    ss.ws_item_sk, ss.net_sales, ss.order_count, ss.avg_sales_per_order, cdm.cd_gender, ca.ca_city
HAVING 
    COUNT(DISTINCT ss.order_count) > 1
ORDER BY 
    ss.net_sales DESC
LIMIT 50;
