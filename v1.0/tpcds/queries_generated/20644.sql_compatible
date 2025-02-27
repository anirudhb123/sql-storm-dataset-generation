
WITH RankedSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sales_price DESC) AS PriceRank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (
        SELECT MAX(d.d_date_sk) 
        FROM date_dim d 
        WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim)
    )
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS TotalOrders,
        SUM(ws.ws_sales_price) AS TotalSpent,
        MAX(ws.ws_sales_price) AS MaxOrderAmount,
        CASE 
            WHEN SUM(ws.ws_sales_price) >= 1000 THEN 'High'
            WHEN SUM(ws.ws_sales_price) < 100 AND COUNT(DISTINCT ws.ws_order_number) = 1 THEN 'Low (Solo)'
            ELSE 'Medium'
        END AS CustomerSpendingGroup
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender
),
ReturnsData AS (
    SELECT
        sr.returned AS ReturnType,
        CASE
            WHEN sr.returned_qty > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS ReturnStatus,
        sr.customer_sk
    FROM (
        SELECT 'Store' AS returned, cr.cr_return_quantity AS returned_qty, cr.cr_returning_customer_sk AS customer_sk
        FROM catalog_returns cr
        UNION ALL
        SELECT 'Web', wr.wr_return_quantity, wr.wr_returning_customer_sk
        FROM web_returns wr
    ) sr
),
FinalSales AS (
    SELECT 
        cs.c_customer_id,
        cs.TotalOrders,
        cs.TotalSpent,
        cs.MaxOrderAmount,
        cs.CustomerSpendingGroup,
        rd.ReturnStatus,
        COALESCE(RANK() OVER (ORDER BY cs.TotalSpent DESC), 0) AS SpendingRank
    FROM CustomerSummary cs
    LEFT JOIN ReturnsData rd ON cs.c_customer_id = rd.customer_sk
)
SELECT 
    fs.c_customer_id,
    fs.TotalOrders,
    fs.TotalSpent,
    fs.MaxOrderAmount,
    fs.CustomerSpendingGroup,
    fs.ReturnStatus,
    CASE 
        WHEN fs.ReturnStatus IS NULL THEN 'No Returns'
        ELSE fs.ReturnStatus 
    END AS FinalReturnStatus,
    RANK() OVER (PARTITION BY fs.CustomerSpendingGroup ORDER BY fs.TotalSpent DESC) AS GroupRank
FROM FinalSales fs
ORDER BY fs.TotalSpent DESC, fs.CustomerSpendingGroup;
