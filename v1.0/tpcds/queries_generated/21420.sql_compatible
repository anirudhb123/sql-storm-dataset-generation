
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS order_count,
        MAX(sd.d_date) AS last_sale
    FROM 
        web_sales ws
    JOIN 
        date_dim sd ON ws.sold_date_sk = sd.d_date_sk
    GROUP BY 
        ws.bill_customer_sk, ws.item_sk
),
ReturnData AS (
    SELECT 
        wr.returning_customer_sk,
        wr.item_sk,
        SUM(wr.return_amt) AS total_returns,
        COUNT(DISTINCT wr.order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk, wr.item_sk
),
CustomerStats AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_returns, 0)) AS net_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        (SELECT 
            bill_customer_sk,
            item_sk,
            SUM(total_sales) AS total_sales
         FROM 
            SalesData
         GROUP BY 
            bill_customer_sk, item_sk) sd ON cd.cd_demo_sk = sd.bill_customer_sk
    LEFT JOIN 
        (SELECT 
            returning_customer_sk,
            item_sk,
            SUM(total_returns) AS total_returns
         FROM 
            ReturnData
         GROUP BY 
            returning_customer_sk, item_sk) rd ON cd.cd_demo_sk = rd.returning_customer_sk
)
SELECT 
    cs.cd_demo_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.cd_credit_rating,
    cs.total_sales,
    cs.total_returns,
    cs.net_sales,
    RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.net_sales DESC) AS sales_rank,
    CASE 
        WHEN cs.cd_purchase_estimate IS NULL THEN 'Unknown Purchase Estimate'
        WHEN cs.net_sales < 0 THEN 'Negative Sales'
        ELSE 'Valid Sales'
    END AS sales_status
FROM 
    CustomerStats cs
WHERE 
    cs.cd_purchase_estimate BETWEEN 1000 AND 5000
    AND (cs.cd_gender IS NULL OR cs.cd_gender IN ('M', 'F'))
ORDER BY 
    sales_rank;
