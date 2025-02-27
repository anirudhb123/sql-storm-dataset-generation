
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_sold_date_sk
),
ReturnData AS (
    SELECT 
        sr.returned_date_sk,
        SUM(sr.return_amt) AS total_returns,
        SUM(sr.return_quantity) AS total_return_qty
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk
),
CombinedData AS (
    SELECT 
        d.d_date_id,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        COALESCE(rd.total_return_qty, 0) AS total_return_qty
    FROM 
        date_dim d
    LEFT JOIN 
        SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
    LEFT JOIN 
        ReturnData rd ON d.d_date_sk = rd.returned_date_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    d.d_date_id,
    cd.purchase_rank,
    cd.cd_purchase_estimate,
    cd.cd_gender || ' | ' || (CASE WHEN cd.cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END) AS demographic_info,
    CASE 
        WHEN cd.purchase_rank <= 10 THEN 'Top Customers' 
        ELSE 'Regular Customers' 
    END AS customer_category,
    SUM(cd.cd_purchase_estimate * (COALESCE(cd.purchase_rank, 1) :: DECIMAL / 10)) OVER (PARTITION BY cd.cd_gender) AS adjusted_purchase
FROM 
    RankedCustomers cd
JOIN 
    CombinedData d ON cd.c_customer_sk = (SELECT ws_bill_customer_sk FROM web_sales ws WHERE ws.ws_sold_date_sk = d.d_date_id LIMIT 1)
WHERE 
    d.total_sales > 1000
ORDER BY 
    cd.purchase_rank;
