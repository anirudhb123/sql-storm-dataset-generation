
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_sales_price) DESC) AS rank
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY 
        cs_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        item i ON r.cs_item_sk = i.i_item_sk
    WHERE 
        r.rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        q.total_sales
    FROM 
        customer_demographics cd
    JOIN 
        (SELECT 
            ws_bill_cdemo_sk,
            SUM(ws_net_paid) AS total_sales
         FROM 
            web_sales
         WHERE 
            ws_sold_date_sk BETWEEN 20200101 AND 20201231
         GROUP BY 
            ws_bill_cdemo_sk) q ON cd.cd_demo_sk = q.ws_bill_cdemo_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT ct.c_customer_sk) AS customer_count,
    SUM(ct.total_sales) AS overall_sales
FROM 
    CustomerDemographics cd
JOIN 
    (SELECT 
        r.cd_demo_sk,
        t.total_sales
     FROM 
        CustomerDemographics r
     JOIN 
        TopItems t ON r.total_sales > 10000) ct ON cd.cd_demo_sk = ct.cd_demo_sk
GROUP BY 
    cd.cd_gender, 
    cd.cd_marital_status
ORDER BY 
    overall_sales DESC;
