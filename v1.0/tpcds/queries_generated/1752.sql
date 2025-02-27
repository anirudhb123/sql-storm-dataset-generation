
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        ranked.total_sales
    FROM 
        RankedSales ranked
    JOIN 
        item ON ranked.ws_item_sk = item.i_item_sk
    WHERE 
        ranked.sales_rank <= 10
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_customer_sk
),
AggregateDemographics AS (
    SELECT 
        cd_demo_sk,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    WHERE 
        cd_credit_rating IS NOT NULL
    GROUP BY 
        cd_demo_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    T.total_sales,
    COALESCE(CR.return_count, 0) AS return_count,
    AD.avg_purchase_estimate,
    AD.total_dependents
FROM 
    customer c
LEFT OUTER JOIN 
    CustomerReturns CR ON c.c_customer_sk = CR.sr_customer_sk
INNER JOIN 
    TopItems T ON c.c_current_cdemo_sk = T.i_item_id
INNER JOIN 
    AggregateDemographics AD ON c.c_current_cdemo_sk = AD.cd_demo_sk
WHERE 
    c.c_birth_year >= 1980 
    AND (c.c_city IS NULL OR c.c_city LIKE 'New%')
ORDER BY 
    T.total_sales DESC, 
    c.c_last_name ASC;
