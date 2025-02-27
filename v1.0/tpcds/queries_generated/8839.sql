
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        rs.total_quantity,
        rs.total_net_paid
    FROM 
        item i
    JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    WHERE 
        rs.sales_rank <= 10
),
SalesByDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ti.total_quantity) AS total_quantity,
        SUM(ti.total_net_paid) AS total_net_paid
    FROM 
        TopItems ti
    JOIN 
        customer c ON ti.i_item_sk = c.c_current_cdemo_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd_gender,
    cd_marital_status,
    total_quantity,
    total_net_paid,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM 
    SalesByDemographics
ORDER BY 
    revenue_rank;
