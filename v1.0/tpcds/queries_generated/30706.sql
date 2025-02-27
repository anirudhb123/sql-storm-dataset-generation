
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.sold_date_sk, 
        ws.item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.sold_date_sk, 
        ws.item_sk
    
    UNION ALL 
    
    SELECT 
        sr.returned_date_sk, 
        sr.item_sk, 
        -SUM(sr.return_quantity) AS total_quantity, 
        -SUM(sr.return_amt) AS total_profit
    FROM 
        store_returns sr
    JOIN 
        date_dim dd ON sr.sr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        sr.returned_date_sk, 
        sr.item_sk
), 
AggregatedSales AS (
    SELECT 
        item_sk, 
        SUM(total_quantity) AS final_quantity, 
        SUM(total_profit) AS final_profit
    FROM 
        SalesCTE
    GROUP BY 
        item_sk
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year < 1990
    GROUP BY 
        cd.cd_demo_sk, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_credit_rating
)
SELECT 
    ads.item_sk, 
    ads.final_quantity, 
    ads.final_profit,
    cd.cd_gender, 
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.num_customers
FROM 
    AggregatedSales ads
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = (
        SELECT 
            cd_demo_sk 
        FROM 
            customer c 
        WHERE 
            c.c_current_addr_sk IS NOT NULL
        LIMIT 1
    )
WHERE 
    ads.final_profit > 0
ORDER BY 
    ads.final_profit DESC, 
    ads.final_quantity DESC
LIMIT 100;
