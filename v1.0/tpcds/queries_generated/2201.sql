
WITH RankedReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(cr_return_number) AS return_count,
        SUM(cr_return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_amt) DESC) AS return_rank
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
), HighReturnCustomers AS (
    SELECT 
        r.returning_customer_sk,
        c.c_first_name,
        c.c_last_name,
        r.return_count,
        r.total_return_amt
    FROM 
        RankedReturns r
    JOIN customer c ON r.returning_customer_sk = c.c_customer_sk
    WHERE 
        r.return_rank <= 10
), CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_credit_rating = 'Good'
), TopStores AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss_ext_sales_price) AS total_sales
    FROM 
        store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
    ORDER BY 
        total_sales DESC
    LIMIT 5
), DailySales AS (
    SELECT 
        d.d_date,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(cs_ext_sales_price) AS total_catalog_sales,
        COALESCE(SUM(ss_ext_sales_price), 0) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_date
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    hrc.return_count,
    hrc.total_return_amt,
    ts.s_store_name,
    ds.total_web_sales,
    ds.total_catalog_sales,
    ds.total_store_sales
FROM 
    HighReturnCustomers hrc
JOIN CustomerDemographics cd ON cd.cd_demo_sk = hrc.returning_customer_sk
JOIN TopStores ts ON ts.s_store_sk = (SELECT ss.s_store_sk FROM store_sales ss ORDER BY ss_total_sales DESC LIMIT 1)
CROSS JOIN DailySales ds
ORDER BY 
    hrc.total_return_amt DESC;
