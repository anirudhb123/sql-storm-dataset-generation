
WITH RECURSIVE PopularItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ss.ss_quantity) AS total_sales
    FROM 
        item i
    JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    WHERE 
        ss.ss_sold_date_sk = (SELECT MAX(sd.d_date_sk) FROM date_dim sd)
    GROUP BY 
        i.i_item_sk, i.i_item_id
    HAVING 
        SUM(ss.ss_quantity) > 100
    UNION ALL
    SELECT 
        pi.i_item_sk,
        pi.i_item_id,
        SUM(ss.ss_quantity) AS total_sales
    FROM 
        PopularItems pi
    JOIN 
        store_sales ss ON pi.i_item_sk = ss.ss_item_sk
    WHERE 
        ss.ss_sold_date_sk < (SELECT MAX(sd.d_date_sk) FROM date_dim sd)
    GROUP BY 
        pi.i_item_sk, pi.i_item_id
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
ItemSalesSummary AS (
    SELECT 
        pi.i_item_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_count
    FROM 
        PopularItems pi
    JOIN 
        store_sales ss ON pi.i_item_sk = ss.ss_item_sk
    GROUP BY 
        pi.i_item_sk
)
SELECT 
    ci.c_customer_sk,
    cd.cd_gender,
    cd.customer_value,
    its.i_item_id,
    its.total_profit,
    its.sales_count
FROM 
    CustomerDemographics cd
JOIN 
    customer c ON cd.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    ItemSalesSummary its ON c.c_current_addr_sk = its.i_item_sk
WHERE 
    (cd.cd_gender = 'M' OR cd.cd_marital_status = 'S')
    AND (its.total_profit IS NOT NULL OR its.sales_count > 0)
ORDER BY 
    total_profit DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
