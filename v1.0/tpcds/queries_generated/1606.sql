
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450565
),

CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),

ReturnStats AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
)

SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_credit_rating,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt,
    COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
    SUM(rs.total_net_profit) AS total_sales_profit,
    RANK() OVER (ORDER BY SUM(rs.total_net_profit) DESC) AS sales_rank
FROM
    CustomerStats cs
LEFT JOIN
    ReturnStats rs ON cs.c_customer_sk = rs.sr_customer_sk
GROUP BY
    cs.c_customer_sk, cs.c_first_name, cs.c_last_name, cs.cd_gender, cs.cd_marital_status, cs.cd_credit_rating
HAVING
    SUM(rs.total_net_profit) > 1000
ORDER BY
    sales_rank;
