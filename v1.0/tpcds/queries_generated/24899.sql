
WITH TopReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS dep_employed_count,
        COALESCE(cd.cd_dep_college_count, 0) AS dep_college_count,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status
        END AS marital_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS sales_count,
        SUM(ws_sales_price) AS total_sales_price,
        SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
),
HighestSellingItems AS (
    SELECT 
        i.i_item_sk,
        ROW_NUMBER() OVER (ORDER BY total_sales_price DESC) AS sales_rank
    FROM ItemSales i
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    COALESCE(tr.total_return_quantity, 0) AS total_returns,
    i.si_item_sk,
    i.total_sales_price,
    i.sales_rank
FROM CustomerDetails cd
LEFT JOIN TopReturns tr ON cd.c_customer_sk = tr.sr_customer_sk
LEFT JOIN HighestSellingItems i ON i.i_item_sk IN (
    SELECT si.i_item_sk
    FROM ItemSales si
    WHERE si.sales_count > (
        SELECT AVG(sales_count) FROM ItemSales
    )
)
WHERE cd.cd_gender IS NOT NULL
AND (cd.cd_purchase_estimate > 1000 OR cd.dep_count < 3)
ORDER BY cd.c_last_name ASC, total_returns DESC;

```
