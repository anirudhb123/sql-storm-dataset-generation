
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
SalesData AS (
    SELECT 
        d.d_date AS sales_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
),
ReturnData AS (
    SELECT 
        d.d_date AS return_date,
        SUM(wr.wr_return_amt_inc_tax) AS total_return,
        COUNT(wr.wr_return_quantity) AS return_count
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
),
CustomerPurchaseStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS purchase_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, full_name, cd.cd_gender
),
RankedCustomers AS (
    SELECT *,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY total_spent DESC) AS rank
    FROM CustomerPurchaseStats
)
SELECT 
    d.sales_date,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_return, 0) AS total_return,
    COALESCE(sd.total_profit, 0) AS total_profit,
    c.full_name,
    c.total_spent,
    c.purchase_count,
    c.rank
FROM SalesData sd
FULL OUTER JOIN ReturnData rd ON sd.sales_date = rd.return_date
LEFT JOIN RankedCustomers c ON c.rank <= 10
ORDER BY d.sales_date, c.rank
LIMIT 100;
