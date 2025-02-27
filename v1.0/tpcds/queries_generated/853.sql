
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
),

AggregateReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returned,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),

CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)

SELECT 
    i.i_item_id,
    COALESCE(rs.rank, 0) AS sales_rank,
    COALESCE(ar.total_returned, 0) AS total_returned,
    COALESCE(ar.total_return_amount, 0) AS total_return_amount,
    cd.cd_gender,
    cd.customer_count
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    AggregateReturns ar ON i.i_item_sk = ar.cr_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = (
        SELECT TOP 1 cd_demo_sk 
        FROM customer c 
        WHERE c.c_customer_sk IN (
            SELECT DISTINCT ws_bill_customer_sk 
            FROM web_sales 
            WHERE ws_item_sk = i.i_item_sk
        )
        ORDER BY NEWID() -- Randomly selects one demographic based on the customers who bought the item
    )
WHERE 
    (rs.rank <= 5 OR rs.rank IS NULL)
ORDER BY 
    i.i_item_sk;
