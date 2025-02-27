
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS Rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
),
AggregateSales AS (
    SELECT
        web_site_sk,
        SUM(ws_sales_price) AS TotalSales
    FROM
        RankedSales
    WHERE
        Rank <= 5
    GROUP BY
        web_site_sk
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price) AS TotalSales
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
HighValueCustomers AS (
    SELECT
        c.c_customer_id,
        ci.TotalSales
    FROM
        CustomerInfo ci
    JOIN
        customer c ON ci.c_customer_id = c.c_customer_id
    WHERE
        ci.TotalSales > (SELECT AVG(TotalSales) FROM CustomerInfo)
)
SELECT 
    wi.web_site_id,
    as.TotalSales AS WebSiteTotalSales,
    hvc.c_customer_id AS HighValueCustomerID,
    hvc.TotalSales AS HighValueCustomerTotalSales
FROM 
    AggregateSales as
JOIN
    web_site wi ON as.web_site_sk = wi.web_site_sk
LEFT JOIN
    HighValueCustomers hvc ON wi.web_site_sk = (SELECT ws.web_site_sk FROM web_sales ws WHERE ws.ws_order_number = hvc.TotalSales)
ORDER BY 
    WebSiteTotalSales DESC, HighValueCustomerTotalSales DESC
LIMIT 10;
