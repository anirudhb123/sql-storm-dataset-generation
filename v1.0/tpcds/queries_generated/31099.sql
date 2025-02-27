
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
), customer_data AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_ext_sales_price) AS customer_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
), return_data AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    s.web_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(SUM(sd.total_sales), 0) AS total_sales,
    COALESCE(rd.total_returns, 0) AS total_returns,
    COALESCE(SUM(sd.total_sales) - rd.total_returns, 0) AS net_sales
FROM 
    sales_data sd
FULL OUTER JOIN 
    customer_data cd ON sd.web_site_sk IN (SELECT ws.web_site_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c))
FULL OUTER JOIN 
    return_data rd ON cd.c_customer_sk = rd.wr_returning_customer_sk
GROUP BY 
    s.web_name, cd.cd_gender, cd.cd_marital_status
ORDER BY 
    net_sales DESC
LIMIT 100;
