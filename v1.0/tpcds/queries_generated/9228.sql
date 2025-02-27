
WITH RankedReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
TopReturnedItems AS (
    SELECT 
        rr.*, 
        ROW_NUMBER() OVER (ORDER BY total_returned_quantity DESC) AS rank
    FROM 
        RankedReturns rr
    WHERE 
        rr.total_returned_quantity > 0
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold_quantity,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount
    FROM 
        web_sales ws
    JOIN 
        TopReturnedItems tri ON ws.ws_item_sk = tri.sr_item_sk
    GROUP BY 
        ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
FinalBenchmark AS (
    SELECT 
        tri.rank,
        tri.sr_item_sk,
        sd.total_sold_quantity,
        sd.total_sales_amount,
        sd.total_discount_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.total_customers
    FROM 
        TopReturnedItems tri
    JOIN 
        SalesData sd ON tri.sr_item_sk = sd.ws_item_sk
    JOIN 
        CustomerDemographics cd ON cd.cd_demo_sk IN (
            SELECT DISTINCT 
                c.c_current_cdemo_sk 
            FROM 
                customer c 
            WHERE 
                c.c_customer_sk IN (
                    SELECT DISTINCT sr_customer_sk 
                    FROM store_returns 
                    WHERE sr_item_sk = tri.sr_item_sk
                )
        )
    WHERE 
        tri.rank <= 10
)
SELECT 
    rank,
    sr_item_sk,
    total_sold_quantity,
    total_sales_amount,
    total_discount_amount,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_customers
FROM 
    FinalBenchmark
ORDER BY 
    total_returned_quantity DESC, total_sales_amount DESC;
