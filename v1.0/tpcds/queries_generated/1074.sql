
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_rec_start_date <= CURRENT_DATE AND (w.web_rec_end_date IS NULL OR w.web_rec_end_date > CURRENT_DATE)
    GROUP BY 
        ws.web_site_id, ws.ws_order_number
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status_desc,
        COALESCE(hd.hd_buy_potential, 'Undefined') AS buying_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
CombData AS (
    SELECT 
        sd.web_site_id,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.marital_status_desc,
        cd.buying_potential,
        sd.total_quantity,
        sd.total_net_paid,
        sd.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY sd.web_site_id ORDER BY sd.total_net_profit DESC) AS rnk
    FROM 
        SalesData sd
    JOIN 
        CustomerData cd ON sd.unique_customers IN (
            SELECT 
                COUNT(*) 
            FROM 
                customer 
            GROUP BY 
                c_customer_sk
        ) 
    WHERE 
        sd.total_net_profit IS NOT NULL
)
SELECT 
    web_site_id,
    c_first_name,
    c_last_name,
    cd_gender,
    marital_status_desc,
    buying_potential,
    total_quantity,
    total_net_paid,
    total_net_profit
FROM 
    CombData
WHERE 
    rnk <= 10 OR (buying_potential = 'High' AND total_net_profit > 10000)
ORDER BY 
    web_site_id, total_net_profit DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
