
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(NULLIF(cd.cd_purchase_estimate, 0), 1) AS adjusted_estimate,
        COUNT(DISTINCT CASE WHEN ws_bill_customer_sk IS NOT NULL THEN ws_order_number END) AS web_orders,
        COUNT(DISTINCT CASE WHEN cs_bill_customer_sk IS NOT NULL THEN cs_order_number END) AS catalog_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(cd.cd_dep_count, 0) DESC) AS dep_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT
        c.*,
        cs.*
    FROM customer c
    JOIN CustomerStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE cs.dep_rank <= 5
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
    UNION ALL
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM catalog_sales cs
    GROUP BY cs.cs_item_sk
),
OrderSummary AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sd.total_quantity_sold, 0) AS total_quantity,
        COALESCE(sd.total_net_profit, 0) AS total_profit,
        RANK() OVER (ORDER BY COALESCE(sd.total_net_profit, 0) DESC) AS profit_rank
    FROM item
    LEFT JOIN SalesData sd ON item.i_item_sk = sd.ws_item_sk
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    os.i_item_id,
    os.i_item_desc,
    os.total_quantity,
    os.total_profit
FROM TopCustomers tc
JOIN OrderSummary os ON tc.c_customer_sk = os.total_profit
WHERE os.profit_rank <= 10
AND (tc.cd_marital_status IS NOT NULL OR tc.cd_gender = 'F')
ORDER BY os.total_profit DESC, tc.c_last_name ASC;
