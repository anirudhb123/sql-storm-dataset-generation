
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopItems AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_profit
    FROM SalesCTE
    WHERE rn <= 5
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        t.total_quantity,
        t.total_profit,
        DENSE_RANK() OVER (ORDER BY t.total_profit DESC) AS rank_profit
    FROM TopItems t
    JOIN item i ON t.ws_item_sk = i.i_item_sk
),
CustomerWithProfits AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(NULLIF(ws.ws_net_profit, 0)) AS total_customer_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cs.total_customer_profit,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_customer_profit DESC) AS gender_rank
    FROM CustomerWithProfits cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
),
BestCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.total_customer_profit
    FROM CustomerDemographics d
    JOIN customer c ON d.cd_demo_sk = c.c_current_cdemo_sk
    WHERE d.gender_rank <= 10
),
FinalReport AS (
    SELECT 
        bc.c_customer_sk,
        bc.c_first_name,
        bc.c_last_name,
        bc.cd_gender,
        bc.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        bc.total_customer_profit
    FROM BestCustomers bc
    LEFT JOIN household_demographics hd ON bc.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.total_customer_profit IS NULL THEN 'No Profit'
        ELSE 'Profit Earned'
    END AS profit_status
FROM FinalReport fr
ORDER BY fr.total_customer_profit DESC, fr.c_last_name ASC;
