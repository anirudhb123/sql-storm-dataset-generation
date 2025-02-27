
WITH Z最好的国度年 临时数据 AS (
    SELECT 
        d.d_year AS 年, 
        COUNT(DISTINCT c.c_customer_id) AS 客户数量,
        COALESCE(SUM(ws.ws_net_profit), 0) AS 网络利润,
        COALESCE(SUM(ss.ss_net_profit), 0) AS 店铺利润,
        COALESCE(SUM(cr.cr_net_loss), 0) AS 目录丢失,
        SUM(CASE WHEN ws.ws_net_profit > ss.ss_net_profit THEN 1 ELSE 0 END) AS 网络胜出
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk OR ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year
),
总览 AS (
    SELECT 
        年,
        客户数量,
        网络利润,
        店铺利润,
        目录丢失,
        网络胜出,
        ROW_NUMBER() OVER (ORDER BY 年) AS 排名
    FROM 
        临时数据
)
SELECT 
    z.*,
    STRING_AGG(CONCAT('排名: ', CAST(排名 AS VARCHAR), ', 网络利润: ', CAST(网络利润 AS VARCHAR)), ', ') OVER (PARTITION BY 年) AS 排名与利润
FROM 
    总览 z
ORDER BY 
    年 DESC;
