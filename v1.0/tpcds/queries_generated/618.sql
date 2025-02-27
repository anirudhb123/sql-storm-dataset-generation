
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451944 -- Filtering for specific date range
    GROUP BY 
        c.c_customer_id, c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        CASE 
            WHEN cd.cd_credit_rating = 'Excellent' THEN 'A'
            WHEN cd.cd_credit_rating = 'Good' THEN 'B'
            ELSE 'C'
        END AS credit_band
    FROM 
        customer_demographics cd
),
TotalReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(COALESCE(sr.sr_return_quantity, 0)) AS total_returns,
        AVG(sr.sr_return_amt_inc_tax) AS avg_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
TopReturningItems AS (
    SELECT 
        i.i_item_id,
        tr.total_returns,
        tr.avg_return_amt,
        ROW_NUMBER() OVER (ORDER BY tr.total_returns DESC) AS return_rank
    FROM 
        item i
    JOIN 
        TotalReturns tr ON i.i_item_sk = tr.sr_item_sk
)
SELECT 
    r.sales_rank,
    cd.cd_gender,
    cd.credit_band,
    tri.i_item_id,
    tri.total_returns,
    tri.avg_return_amt
FROM 
    RankedSales r
JOIN 
    CustomerDemographics cd ON r.c_customer_id = cd.cd_demo_sk
JOIN 
    TopReturningItems tri ON r.sales_rank <= 5 -- Include top 5 returning items
WHERE 
    cd.buy_potential IS NOT NULL
ORDER BY 
    r.total_sales DESC, tri.total_returns DESC;
