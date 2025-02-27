
WITH CustomerReturnInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt), 0) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
ItemSales AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS sale_count,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.first_name,
    c.last_name,
    ci.total_returns,
    ci.total_return_amount,
    cd.male_count,
    cd.female_count,
    is.sale_count,
    is.total_sales,
    ROW_NUMBER() OVER (PARTITION BY ci.total_returns ORDER BY is.total_sales DESC) AS rank_by_sales,
    CASE 
        WHEN ci.total_returns > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM 
    CustomerReturnInfo ci
JOIN 
    customer c ON ci.c_customer_sk = c.c_customer_sk
JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    ItemSales is ON c.c_current_addr_sk = is.ws_item_sk
WHERE 
    ci.total_return_amount > 100
    AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    AND ci.return_count > (
        SELECT 
            AVG(total_return_count)
        FROM 
            (SELECT COUNT(*) AS total_return_count
             FROM store_returns
             GROUP BY sr_customer_sk) AS sub
    )
ORDER BY 
    ci.total_return_amount DESC;
