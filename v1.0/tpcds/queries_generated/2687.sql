
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
),
TotalSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ReturnsInfo AS (
    SELECT 
        sr_item_sk,
        COUNT(*) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(ri.return_count, 0) AS return_count,
    rs.ws_sales_price AS highest_price
FROM 
    CustomerInfo ci
LEFT JOIN 
    TotalSales ts ON ci.c_customer_sk = (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk IN (SELECT ws_item_sk FROM RankedSales WHERE sales_rank = 1)
        LIMIT 1
    )
LEFT JOIN 
    ReturnsInfo ri ON ri.sr_item_sk = (
        SELECT 
            ws_item_sk FROM web_sales 
        WHERE 
            ws_order_number = (SELECT MAX(ws_order_number) FROM web_sales)
        LIMIT 1
    )
LEFT JOIN 
    RankedSales rs ON rs.sales_rank = 1
WHERE 
    ci.cd_gender = 'F' 
    AND (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL)
ORDER BY 
    total_sales DESC, ci.c_last_name ASC;
