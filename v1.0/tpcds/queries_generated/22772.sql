
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales AS ws
    JOIN 
        item AS it ON ws.ws_item_sk = it.i_item_sk
    WHERE 
        it.i_current_price BETWEEN 10.00 AND 100.00
    GROUP BY 
        ws.ws_item_sk
), 
HighPerformers AS (
    SELECT 
        *, 
        CASE 
            WHEN total_net_profit > 1000 THEN 'High Profit'
            ELSE 'Low Profit'
        END AS profit_category
    FROM 
        RankedSales
    WHERE 
        rank <= 10
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_marital_status,
        cd.cd_gender,
        c.c_birth_month,
        c.c_birth_day,
        COALESCE(c.c_birth_year, 1970) AS birth_year,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_preferred_cust_flag = 'Y'
)

SELECT 
    c.c_customer_id,
    it.i_item_id,
    hp.total_quantity,
    hp.total_net_profit,
    cd.cd_marital_status,
    cd.cd_gender,
    cd.c_birth_month,
    COALESCE(NULLIF(cd.c_birth_day, 0), 'Not Specified') AS birth_day,
    cd.birth_year,
    hp.profit_category 
FROM 
    HighPerformers AS hp
JOIN 
    item AS it ON hp.ws_item_sk = it.i_item_sk
JOIN 
    web_sales AS ws ON it.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    CustomerDetails AS cd ON ws.ws_bill_customer_sk = cd.c_customer_id
WHERE 
    hp.total_quantity > (
        SELECT 
            AVG(total_quantity) 
        FROM 
            HighPerformers
        WHERE 
            profit_category = 'High Profit'
    )
ORDER BY 
    hp.total_net_profit DESC,
    cd.gender_rank
LIMIT 50;
