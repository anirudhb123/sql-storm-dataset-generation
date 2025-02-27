
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk AS customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.customer_sk,
        cr.total_returns,
        cr.total_returned_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        CustomerReturns cr
    JOIN 
        customer_demographics cd ON cr.customer_sk = cd.cd_demo_sk
    WHERE 
        cr.total_returned_amount > 500
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
StoreSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_sold,
        SUM(ss_sales_price) AS total_sales
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
TotalSales AS (
    SELECT 
        item_sk,
        SUM(total_sold) AS total_sold,
        SUM(total_sales) AS total_sales
    FROM (
        SELECT 
            ws_item_sk AS item_sk,
            total_sold,
            total_sales
        FROM 
            ItemSales
        UNION ALL
        SELECT 
            ss_item_sk AS item_sk,
            total_sold,
            total_sales
        FROM 
            StoreSales
    ) AS combined_sales
    GROUP BY 
        item_sk
)
SELECT 
    cu.c_first_name,
    cu.c_last_name,
    crc.total_returns,
    crc.total_returned_amount,
    COALESCE(ts.total_sold, 0) AS total_sold,
    COALESCE(ts.total_sales, 0) AS total_sales,
    RANK() OVER (PARTITION BY cu.c_customer_sk ORDER BY crc.total_returned_amount DESC) AS rank
FROM 
    HighReturnCustomers crc
JOIN 
    customer cu ON crc.customer_sk = cu.c_customer_sk
LEFT JOIN 
    TotalSales ts ON ts.item_sk = ANY(ARRAY(SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = cu.c_customer_sk))
WHERE 
    cu.c_birth_year > 1980 AND
    crc.cd_marital_status = 'M' AND
    crc.cd_gender IS NOT NULL
ORDER BY 
    total_returned_amount DESC, total_sales DESC;
