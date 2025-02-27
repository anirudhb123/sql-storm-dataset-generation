
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighProfitItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_profit,
        i.i_item_desc
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.profit_rank <= 10
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(sws.ws_net_profit) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales
    FROM 
        customer_demographics cd
    LEFT JOIN 
        catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    LEFT JOIN 
        web_sales ws ON cd.cd_demo_sk = ws.ws_bill_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    c.c_customer_sk,
    c_total.order_count,
    c_total.total_spent,
    cd.cd_gender,
    cd.cd_marital_status,
    hi.total_quantity,
    hi.total_net_profit
FROM 
    CustomerSummary c_total
JOIN 
    customer c ON c.c_customer_sk = c_total.c_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    HighProfitItems hi ON hi.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    c_total.total_spent IS NOT NULL
ORDER BY 
    c_total.total_spent DESC
FETCH FIRST 50 ROWS ONLY;

-- Further refining with outer joins to include customers with null spending but details in demographics
SELECT 
    DISTINCT c.c_customer_sk,
    COALESCE(c_total.order_count, 0) AS order_count,
    COALESCE(c_total.total_spent, 0) AS total_spent,
    cd.cd_gender,
    cd.cd_marital_status,
    hi.total_quantity,
    hi.total_net_profit
FROM 
    customer c
FULL OUTER JOIN 
    CustomerSummary c_total ON c.c_customer_sk = c_total.c_customer_sk
FULL OUTER JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    HighProfitItems hi ON hi.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    (c_total.total_spent IS NULL OR c_total.total_spent > 1000)
    AND (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NULL)

ORDER BY 
    COALESCE(c_total.total_spent, 0) DESC, c.c_customer_sk
LIMIT 100;
