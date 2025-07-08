
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_profit,
        i.i_item_desc,
        i.i_current_price,
        RANK() OVER (ORDER BY r.total_profit DESC) AS profit_rank
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    t.total_quantity AS web_sales_quantity,
    t.total_profit AS web_sales_profit,
    r.total_returned AS total_returns,
    r.return_count AS returns_count,
    (CASE 
        WHEN r.total_returned IS NULL THEN 0 
        ELSE (r.total_returned * 100.0 / NULLIF(t.total_quantity, 0)) 
    END) AS return_percentage
FROM 
    customer c
LEFT JOIN 
    CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
JOIN 
    TopSellingItems t ON t.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    t.profit_rank <= 10
ORDER BY 
    return_percentage DESC;
