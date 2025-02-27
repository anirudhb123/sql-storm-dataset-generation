
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id, 
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(*) AS demographics_count 
    FROM 
        customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
TotalReturns AS (
    SELECT 
        sr_returning_customer_sk, 
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
    UNION ALL
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_amt) AS total_return_amt, 
        COUNT(wr_order_number) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
AggregatedData AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.web_orders,
        cs.store_orders,
        cs.catalog_orders,
        COALESCE(td.total_return_amt, 0) AS total_return_amt,
        COALESCE(td.total_returns, 0) AS total_returns,
        cd.demographics_count
    FROM 
        CustomerSales cs
    LEFT JOIN TotalReturns td ON cs.c_customer_id = td.sr_returning_customer_sk OR cs.c_customer_id = td.wr_returning_customer_sk
    LEFT JOIN CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk
)
SELECT 
    ad.c_customer_id, 
    ad.total_sales, 
    ad.web_orders, 
    ad.store_orders, 
    ad.catalog_orders,
    ad.total_return_amt,
    ad.total_returns,
    CASE 
        WHEN ad.total_sales > 1000 THEN 'High'
        WHEN ad.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    RANK() OVER (ORDER BY ad.total_sales DESC) AS sales_rank
FROM 
    AggregatedData ad
WHERE 
    ad.demographics_count > 1
ORDER BY 
    ad.total_sales DESC;
