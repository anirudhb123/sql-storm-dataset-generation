
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
), 
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        SUM(rs.ws_quantity) AS total_quantity, 
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 3 
    GROUP BY 
        rs.ws_item_sk
), 
CustomerSummary AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), 
DemographicSummary AS (
    SELECT 
        cd.cd_gender, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(ts.total_sales) AS total_sales
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopSales ts ON c.c_customer_sk IN (SELECT ws.ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_item_sk = ts.ws_item_sk)
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ds.cd_gender,
    ds.customer_count, 
    ds.total_sales,
    cs.order_count,
    cs.total_profit
FROM 
    DemographicSummary ds
JOIN 
    CustomerSummary cs ON ds.customer_count > 0
ORDER BY 
    ds.total_sales DESC, 
    ds.customer_count DESC;
