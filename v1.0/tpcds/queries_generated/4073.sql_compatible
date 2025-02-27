
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_net_loss) AS total_return_loss
    FROM
        web_returns
    GROUP BY
        wr_returning_customer_sk
),
TopSellingItems AS (
    SELECT 
        r.ws_item_sk, 
        r.total_quantity, 
        r.total_net_paid, 
        ROW_NUMBER() OVER (ORDER BY r.total_net_paid DESC) AS row_num
    FROM 
        RankedSales r
    WHERE 
        r.rank = 1
)
SELECT 
    c.c_customer_id,
    COALESCE(ct.return_count, 0) AS customer_return_count,
    COALESCE(ct.total_return_loss, 0) AS customer_total_return_loss,
    COALESCE(t.total_quantity, 0) AS total_quantity_sold,
    COALESCE(t.total_net_paid, 0) AS total_net_paid
FROM 
    customer c
LEFT JOIN 
    CustomerReturns ct ON c.c_customer_sk = ct.wr_returning_customer_sk
LEFT JOIN 
    TopSellingItems t ON t.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    c.c_current_addr_sk IS NOT NULL
ORDER BY 
    c.c_customer_id;
