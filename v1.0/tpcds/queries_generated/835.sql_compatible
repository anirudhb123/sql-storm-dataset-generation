
WITH RankedSales AS (
    SELECT 
        ws.ws_customer_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_customer_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        ws.ws_sold_date_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
RecentReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        wr.wr_returning_customer_sk, wr.wr_item_sk
),
FinalSales AS (
    SELECT 
        cs.cs_bill_customer_sk AS customer_id,
        cs.cs_item_sk AS item_id,
        SUM(cs.cs_quantity) AS total_sales_quantity,
        SUM(cs.cs_net_paid) AS total_sales,
        COALESCE(rr.total_return_quantity, 0) AS total_returned_quantity,
        COALESCE(rr.return_count, 0) AS total_returns
    FROM 
        catalog_sales cs
    LEFT JOIN 
        RecentReturns rr ON cs.cs_bill_customer_sk = rr.wr_returning_customer_sk AND cs.cs_item_sk = rr.wr_item_sk
    GROUP BY 
        cs.cs_bill_customer_sk, cs.cs_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
    INNER JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    WHERE 
        c.c_first_shipto_date_sk < (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2021)
)
SELECT 
    cs.customer_id,
    cs.item_id,
    cs.total_sales_quantity,
    cs.total_sales,
    cs.total_returned_quantity,
    cs.total_returns,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate,
    CASE 
        WHEN cs.total_sales > 10000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS sales_category
FROM 
    FinalSales cs
LEFT JOIN 
    CustomerDemographics cd ON cs.customer_id = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M')
    AND (cs.total_sales > 5000 OR cs.total_returned_quantity > 5)
ORDER BY 
    sales_category ASC, cs.total_sales DESC
LIMIT 100;
