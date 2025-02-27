
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0
    GROUP BY 
        ws.ws_item_sk
), 
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        COUNT(DISTINCT CASE WHEN cd.cd_credit_rating IN ('A', 'B') THEN cd.cd_demo_sk END) AS good_credit_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
),
ReturnsData AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    sd.ws_item_sk,
    sd.total_quantity,
    sd.total_sales,
    cs.c_customer_sk,
    cs.gender,
    cs.married_count,
    cs.good_credit_count,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(rd.total_returned_amount, 0.00) AS total_returned_amount,
    CASE 
        WHEN sd.total_sales > 1000 THEN 'High Value Item'
        WHEN sd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Item'
        ELSE 'Low Value Item'
    END AS item_value_category
FROM 
    SalesData sd
JOIN 
    CustomerStats cs ON cs.c_customer_sk = (
        SELECT TOP 1 c.c_customer_sk
        FROM customer c
        WHERE c.c_current_addr_sk IS NOT NULL
        ORDER BY NEWID()  -- Random customer selection
    )
LEFT JOIN 
    ReturnsData rd ON sd.ws_item_sk = rd.sr_item_sk
WHERE 
    sd.sales_rank <= 10
    AND NOT EXISTS (
        SELECT 1 
        FROM web_returns wr
        WHERE wr.wr_item_sk = sd.ws_item_sk 
        AND wr.wr_return_quantity > 0
    )
ORDER BY 
    sd.total_sales DESC;
