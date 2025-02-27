
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        sd.sales_total,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY sd.sales_total DESC) AS gender_rank
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN (
            SELECT 
                ss_customer_sk, 
                SUM(ss_net_paid) AS sales_total
            FROM 
                store_sales
            GROUP BY 
                ss_customer_sk
        ) sd ON c.c_customer_sk = sd.ss_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
TopCustomers AS (
    SELECT 
        cst.c_customer_sk,
        cst.c_first_name,
        cst.c_last_name,
        cst.cd_gender,
        cst.cd_marital_status,
        cst.sales_total
    FROM 
        CustomerStats cst
    WHERE 
        cst.gender_rank <= 10
),
TopItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 10010
    GROUP BY 
        ws.ws_item_sk
),
FinalResult AS (
    SELECT 
        tc.c_first_name,
        tc.c_last_name,
        tc.cd_gender,
        ti.total_quantity,
        ti.total_profit,
        CASE 
            WHEN ti.total_profit IS NULL THEN 'No Profit'
            ELSE 'Profitable'
        END AS profit_status
    FROM 
        TopCustomers tc
        LEFT JOIN TopItems ti ON tc.c_customer_sk = ti.ws_item_sk
)
SELECT 
    f.*,
    COALESCE(SUM(ws.ws_net_paid) OVER (PARTITION BY f.cd_gender), 0) AS total_spent
FROM 
    FinalResult f
ORDER BY 
    f.cd_gender, f.total_profit DESC;
