
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws_item_sk
),
TopSellingItems AS (
    SELECT
        rs.ws_item_sk,
        rs.total_sales,
        i.i_item_id,
        i.i_item_desc
    FROM
        RankedSales rs
    JOIN
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE
        rs.sales_rank <= 10
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS customer_total_spent
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY
        c.c_customer_sk
),
DemographicAnalysis AS (
    SELECT
        cd.cd_gender,
        AVG(cs.customer_total_spent) AS avg_spent
    FROM
        CustomerSales cs
    JOIN
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
)
SELECT
    tsi.i_item_id,
    tsi.i_item_desc,
    da.cd_gender,
    da.avg_spent
FROM
    TopSellingItems tsi
JOIN
    DemographicAnalysis da ON da.cd_gender = (
        SELECT 
            cd.cd_gender 
        FROM 
            customer_demographics cd
        WHERE 
            cd.cd_demo_sk = (
                SELECT 
                    c.c_current_cdemo_sk
                FROM 
                    customer c
                WHERE 
                    c.c_customer_sk IN (SELECT DISTINCT c_customer_sk FROM web_sales WHERE ws_item_sk = tsi.ws_item_sk)
                FETCH FIRST 1 ROWS ONLY
            )
        FETCH FIRST 1 ROWS ONLY
    )
ORDER BY
    tsi.total_sales DESC, da.avg_spent DESC;
