
WITH RankedSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
HighVolumeItems AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item ON rs.ss_item_sk = item.i_item_sk
    WHERE 
        rs.rank <= 10
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    hvi.i_item_id,
    hvi.i_item_desc,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_profit
FROM 
    HighVolumeItems hvi
JOIN 
    CustomerDemographics cd ON hvi.total_sales > cd.total_profit
ORDER BY 
    hvi.total_sales DESC, cd.total_profit DESC;
