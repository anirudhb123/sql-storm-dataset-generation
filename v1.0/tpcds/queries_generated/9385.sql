
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 90
    GROUP BY 
        ws.ws_item_sk, i.i_item_desc
), 
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.i_item_desc,
        rs.total_quantity,
        rs.total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.sales_rank <= 10
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ts.total_sales) AS total_sales_by_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopSales ts ON ts.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    GROUP BY 
        cd.cd_gender
)
SELECT 
    cd.cd_gender,
    cd.customer_count,
    cd.total_sales_by_gender,
    ROUND((cd.total_sales_by_gender / (SELECT SUM(total_sales) FROM TopSales)) * 100, 2) AS sales_percentage
FROM 
    CustomerDemographics cd
ORDER BY 
    cd.total_sales_by_gender DESC;
