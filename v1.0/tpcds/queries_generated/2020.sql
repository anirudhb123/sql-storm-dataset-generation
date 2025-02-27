
WITH SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY 
        ws_bill_customer_sk, ws_item_sk
),
TopCustomers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cu.c_first_name,
        cu.c_last_name,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        SalesData sd
    JOIN 
        customer cu ON sd.ws_bill_customer_sk = cu.c_customer_sk
    JOIN 
        customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        sd.rank_profit <= 5
),
ItemStats AS (
    SELECT
        i.i_item_sk,
        i.i_item_desc,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM
        item i
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    is.i_item_desc,
    is.total_returns,
    is.total_return_amt,
    tc.total_quantity,
    tc.total_net_profit,
    CASE 
        WHEN tc.total_net_profit IS NULL THEN 'No Profit'
        WHEN tc.total_net_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM 
    TopCustomers tc
JOIN 
    ItemStats is ON tc.ws_item_sk = is.i_item_sk
ORDER BY 
    tc.total_net_profit DESC, is.total_return_amt DESC
FETCH FIRST 10 ROWS ONLY;
