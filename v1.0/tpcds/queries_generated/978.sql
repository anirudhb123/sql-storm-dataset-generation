
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
),
TopSales AS (
    SELECT 
        sd.*,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS row_num
    FROM SalesData sd
    WHERE profit_rank <= 10
),
CustomerData AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_dep_count,
        cm.c_month,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(DISTINCT wr.wr_order_number) AS return_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returned_customer_sk
    JOIN (
        SELECT DISTINCT
            d.d_month AS c_month
        FROM date_dim d
        WHERE d.d_year = 2023
    ) cm ON cm.c_month = EXTRACT(MONTH FROM wr.wr_returned_date_sk)
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count, cm.c_month
)
SELECT 
    ts.row_num,
    ts.total_quantity,
    ts.total_profit,
    ts.order_count,
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_returns,
    cd.return_count
FROM TopSales ts
JOIN CustomerData cd ON cd.c_customer_id IS NOT NULL
WHERE 
    (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
    AND (cd.total_returns IS NULL OR cd.total_returns > 100)
ORDER BY ts.row_num, total_profit DESC;
