
WITH SalesSummary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name
),
TopCustomers AS (
    SELECT *
    FROM SalesSummary
    WHERE profit_rank <= 10
),
PopularItems AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        RANK() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM
        web_sales ws
    JOIN (
        SELECT DISTINCT ws_bill_customer_sk
        FROM web_sales
        WHERE ws_ship_date_sk BETWEEN 2462420 AND 2464731
    ) recent_purchases ON ws.ws_bill_customer_sk = recent_purchases.ws_bill_customer_sk
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_quantity) > 100
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS num_customers
    FROM
        customer demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_profit,
    pi.total_quantity_sold,
    cd.num_customers,
    CASE 
        WHEN cd.num_customers IS NULL THEN 'Unknown'
        ELSE cd.cd_gender
    END AS gender_distribution
FROM
    TopCustomers tc
LEFT JOIN PopularItems pi ON tc.c_customer_sk = pi.ws_item_sk
LEFT JOIN CustomerDemographics cd ON tc.c_customer_sk = cd.cd_demo_sk
ORDER BY
    tc.total_profit DESC, 
    pi.total_quantity_sold DESC;
