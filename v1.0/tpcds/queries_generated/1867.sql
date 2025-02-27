
WITH CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_return_qty,
        SUM(wr.return_amt) AS total_return_amount,
        SUM(wr.return_tax) AS total_return_tax
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
StoreSalesView AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_store_qty,
        SUM(ss.ss_net_profit) AS total_store_profit
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.ss_item_sk
),
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown Estimate'
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value_segment
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
),
SalesData AS (
    SELECT 
        COALESCE(ss.ss_item_sk, cs.cs_item_sk) AS item_sk,
        COALESCE(ss.total_store_profit, 0) AS store_profit,
        COALESCE(cs.cs_ext_sales_price, 0) AS catalog_sales_price,
        COALESCE(cr.total_return_amount, 0) AS total_returns
    FROM 
        StoreSalesView ss
    FULL OUTER JOIN 
        catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk
    FULL OUTER JOIN 
        CustomerReturns cr ON cr.returning_customer_sk = 
            (SELECT 
                c.c_customer_sk 
            FROM 
                customer c 
            WHERE 
                c.c_current_addr_sk IS NOT NULL 
            LIMIT 1)
)
SELECT 
    item_sk,
    store_profit,
    catalog_sales_price,
    total_returns,
    CASE 
        WHEN store_profit > 2000 AND total_returns > 100 THEN 'High Risk'
        WHEN catalog_sales_price > 1500 THEN 'Potential Gold Mine'
        ELSE 'Stable'
    END AS sales_risk_category
FROM 
    SalesData
WHERE 
    (store_profit > 0 OR catalog_sales_price > 0)
ORDER BY 
    sales_risk_category DESC, item_sk
LIMIT 50;
