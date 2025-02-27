
WITH RankedSales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        SUM(ws.net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_paid) DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws.bill_customer_sk, ws.item_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        c.c_customer_sk IN (SELECT DISTINCT bill_customer_sk FROM RankedSales WHERE rank_sales <= 5)
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.gender,
    SUM(rs.total_net_paid) AS total_spent,
    STRING_AGG(CONVERT(varchar, i.i_item_id) + ': ' + CONVERT(varchar, SUM(ws.ws_quantity)), ', ') AS purchased_items
FROM 
    TopCustomers tc
JOIN RankedSales rs ON tc.c_customer_sk = rs.bill_customer_sk
JOIN item i ON i.i_item_sk = rs.item_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_bill_customer_sk = tc.c_customer_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.gender
HAVING 
    SUM(rs.total_net_paid) > 1000
ORDER BY 
    total_spent DESC
OPTION (MAXRECURSION 0);
