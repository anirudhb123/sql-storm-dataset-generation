
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
),
TotalReturns AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returned_quantity,
        SUM(cr_return_amount) AS total_returned_amount
    FROM 
        catalog_returns
    GROUP BY 
        cr_item_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(CASE WHEN rs.SalesRank = 1 THEN rs.ws_ext_sales_price ELSE 0 END) AS top_selling_price,
    COALESCE(SUM(tr.total_returned_quantity), 0) AS total_returns,
    COALESCE(SUM(tr.total_returned_amount), 0) AS total_returned_amount
FROM 
    CustomerDetails cd
JOIN 
    RankedSales rs ON cd.c_customer_id = (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = rs.ws_item_sk LIMIT 1)
LEFT JOIN 
    TotalReturns tr ON rs.ws_item_sk = tr.cr_item_sk
GROUP BY 
    cd.c_customer_id, cd.cd_gender, cd.cd_marital_status
HAVING 
    SUM(CASE WHEN rs.SalesRank = 1 THEN rs.ws_ext_sales_price ELSE 0 END) > 100
ORDER BY 
    total_returns DESC, cd.c_customer_id;
