
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
HighProfitSales AS (
    SELECT 
        sales.ws_order_number,
        SUM(sales.ws_net_profit) AS total_net_profit,
        COUNT(sales.ws_item_sk) AS total_items
    FROM 
        SalesData sales
    WHERE 
        sales.rn <= 3
    GROUP BY 
        sales.ws_order_number
),
CustomerReturns AS (
    SELECT 
        cr.return_order_number,
        SUM(COALESCE(cr.return_amt, 0)) AS total_return_amt
    FROM 
        (SELECT wr.wr_order_number AS return_order_number, wr.wr_return_amt
         FROM web_returns wr
         INNER JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
         WHERE wr.wr_return_date BETWEEN (SELECT MIN(d_date) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date) FROM date_dim WHERE d_year = 2023)) 
         ) cr
    GROUP BY 
        cr.return_order_number
)
SELECT 
    c.c_customer_id,
    COALESCE(SUM(hp.total_net_profit), 0) AS net_profit,
    COALESCE(SUM(cr.total_return_amt), 0) AS total_return
FROM 
    customer c
LEFT JOIN 
    HighProfitSales hp ON c.c_customer_id IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_order_number = hp.ws_order_number)
LEFT JOIN 
    CustomerReturns cr ON cr.return_order_number IN (SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    c.c_birth_year < (YEAR(CURDATE()) - 18)
GROUP BY 
    c.c_customer_id
ORDER BY 
    net_profit DESC
FETCH FIRST 10 ROWS ONLY;
