
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk, ws.ws_net_profit ORDER BY ws.ws_sold_date_sk) AS profit_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_net_profit > 0
    GROUP BY ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        ws.ws_item_sk,
        total_sold,
        rank
    FROM RankedSales
    WHERE rank <= 10
),
ItemDemographics AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(cd.cd_marital_status, 'S') AS marital_status,
        MAX(cd.cd_credit_rating) AS credit_rating
    FROM item i
    LEFT JOIN customer c ON i.i_item_sk = c.c_current_cdemo_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY i.i_item_sk, i.i_item_desc, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    i.i_item_desc,
    its.total_sold,
    id.gender,
    id.marital_status,
    id.credit_rating
FROM TopSellingItems its
JOIN ItemDemographics id ON its.ws_item_sk = id.i_item_sk
LEFT JOIN store_sales ss ON id.i_item_sk = ss.ss_item_sk AND ss.ss_sold_date_sk = (
    SELECT MAX(ss2.ss_sold_date_sk) 
    FROM store_sales ss2 
    WHERE ss2.ss_item_sk = id.i_item_sk
)
WHERE ss.ss_sold_date_sk IS NULL OR ss.ss_net_profit < (
    SELECT AVG(ss3.ss_net_profit)
    FROM store_sales ss3
    WHERE ss3.ss_item_sk = id.i_item_sk
)
ORDER BY its.total_sold DESC, id.gender
LIMIT 5;
