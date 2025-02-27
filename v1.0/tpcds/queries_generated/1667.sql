
WITH SalesData AS (
    SELECT 
        w.warehouse_name,
        SUM(ws.net_paid_inc_ship_tax) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        COUNT(DISTINCT ws.ship_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) 
        AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        w.warehouse_name
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        hd.buy_potential IS NOT NULL
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status, cd_income_band_sk
),
ReturnsData AS (
    SELECT 
        SUM(CASE 
            WHEN wr.return_amt > 0 THEN wr.return_amt 
            ELSE 0 
        END) AS total_web_returns,
        SUM(CASE 
            WHEN sr.return_amt > 0 THEN sr.return_amt 
            ELSE 0 
        END) AS total_store_returns
    FROM 
        web_returns wr
    FULL OUTER JOIN 
        store_returns sr ON wr.return_number = sr.return_number
    WHERE 
        (wr.returned_date_sk IS NOT NULL OR sr.returned_date_sk IS NOT NULL)
)
SELECT 
    s.warehouse_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    sd.total_sales,
    sd.total_orders,
    rd.total_web_returns,
    rd.total_store_returns
FROM 
    SalesData sd
JOIN 
    CustomerDemographics cd ON cd.customer_count > 0
JOIN 
    ReturnsData rd ON 1=1
WHERE 
    (cd.cd_gender = 'F' AND sd.total_sales > 1000) 
    OR (cd.cd_marital_status = 'M' AND sd.total_orders > 50)
ORDER BY 
    sd.total_sales DESC, cd.customer_count ASC;
