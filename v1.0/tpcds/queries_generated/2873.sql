
WITH RankedSales AS (
    SELECT
        ws_bill_customer_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
ReturnSummary AS (
    SELECT
        sr_returning_customer_sk,
        SUM(sr_return_amt) AS total_returned
    FROM
        store_returns
    GROUP BY
        sr_returning_customer_sk
),
FinalReport AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.total_orders,
        cs.total_spent,
        COALESCE(rs.total_returned, 0) AS total_returned,
        COALESCE(rs.total_returned, 0) / NULLIF(cs.total_spent, 0) AS return_rate,
        COUNT(rs.sales_rank) AS recent_high_value_items
    FROM
        CustomerSummary cs
        LEFT JOIN RankedSales rs ON cs.c_customer_sk = rs.ws_bill_customer_sk AND rs.sales_rank <= 5
        LEFT JOIN ReturnSummary r ON cs.c_customer_sk = r.sr_returning_customer_sk
    WHERE
        cs.total_spent > 0
    GROUP BY
        cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.cd_gender, cs.cd_marital_status, cs.total_orders, cs.total_spent, rs.total_returned
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.cd_marital_status,
    f.total_orders,
    f.total_spent,
    f.total_returned,
    f.return_rate,
    f.recent_high_value_items
FROM 
    FinalReport f
WHERE 
    f.return_rate < 0.2
ORDER BY 
    f.total_spent DESC;
