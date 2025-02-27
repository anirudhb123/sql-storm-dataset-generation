
WITH RECURSIVE SalesAnalysis AS (
    SELECT
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk ASC) AS row_num
    FROM
        web_sales
    WHERE
        ws_sales_price IS NOT NULL 
),
AggregateSales AS (
    SELECT 
        a.ws_item_sk,
        SUM(a.ws_sales_price * a.ws_quantity) AS total_sales,
        COUNT(DISTINCT a.ws_sold_date_sk) AS sales_days,
        MAX(a.ws_sales_price) AS max_price,
        MIN(a.ws_sales_price) AS min_price
    FROM 
        SalesAnalysis a
    WHERE 
        a.rank <= 5
    GROUP BY 
        a.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_age_state,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales cs ON cs.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_age_state
)
SELECT 
    c.customer_id,
    cd_total.total_spent,
    asales.total_sales,
    asales.sales_days,
    asales.max_price,
    asales.min_price
FROM 
    customer c
JOIN 
    CustomerDemographics cd_total ON c.c_customer_sk = cd_total.c_customer_sk
JOIN 
    AggregateSales asales ON asales.ws_item_sk IN (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_bill_customer_sk = c.c_customer_sk
    )
WHERE 
    cd_total.total_orders > 0 AND
    cd_total.total_spent IS NOT NULL
ORDER BY 
    total_spent DESC
LIMIT 50;
