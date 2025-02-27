
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk
    HAVING 
        total_sales > (
            SELECT AVG(ws_inner.ws_sales_price)
            FROM web_sales ws_inner
            WHERE ws_inner.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        )
), 
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_income_band_sk ORDER BY COUNT(DISTINCT ws.ws_order_number) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, hd.hd_income_band_sk
),
ProductReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
    HAVING 
        total_returns > (
            SELECT AVG(wr_inner.wr_return_quantity)
            FROM web_returns wr_inner
        )
)
SELECT 
    s.site_sales_rank,
    h.c_first_name,
    h.c_last_name,
    COALESCE(SUM(pr.total_returns), 0) AS total_product_returns,
    s.total_sales AS sales_data
FROM 
    SalesData s
LEFT JOIN 
    HighValueCustomers h ON s.web_site_sk = h.hd_income_band_sk
LEFT JOIN 
    ProductReturns pr ON h.c_customer_sk = pr.wr_item_sk
WHERE 
    s.sales_rank <= 10 AND 
    (h.customer_rank IS NULL OR h.customer_rank <= 5)
GROUP BY 
    s.site_sales_rank, h.c_first_name, h.c_last_name, s.total_sales
ORDER BY 
    total_product_returns DESC, sales_data DESC;
