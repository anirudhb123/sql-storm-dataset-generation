
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
), 
TopCustomers AS (
    SELECT 
        ws_bill_customer_sk,
        total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cad.ca_city,
        cad.ca_state,
        COALESCE(NULLIF(cd.cd_credit_rating, 'Good'), 'Unknown') AS adjusted_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address cad ON c.c_current_addr_sk = cad.ca_address_sk
), 
SalesAnalysis AS (
    SELECT 
        td.ws_bill_customer_sk,
        SUM(td.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT td.ws_order_number) AS order_count
    FROM 
        web_sales td
    JOIN 
        TopCustomers tc ON td.ws_bill_customer_sk = tc.ws_bill_customer_sk
    GROUP BY 
        td.ws_bill_customer_sk
), 
FinalReport AS (
    SELECT 
        cd.c_customer_id,
        sa.total_net_profit,
        sa.order_count,
        CASE 
            WHEN sa.total_net_profit IS NULL THEN 'No Profit Data'
            WHEN sa.total_net_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status,
        cd.adjusted_credit_rating,
        CONCAT(cd.ca_city, ', ', cd.ca_state) AS location
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesAnalysis sa ON cd.c_customer_id = sa.ws_bill_customer_sk
)
SELECT 
    fr.c_customer_id,
    fr.total_net_profit,
    fr.order_count,
    fr.profit_status,
    fr.adjusted_credit_rating,
    fr.location
FROM 
    FinalReport fr
WHERE 
    fr.profit_status = 'Profit'
    OR (fr.profit_status = 'No Profit Data' AND fr.adjusted_credit_rating = 'Unknown')
ORDER BY 
    fr.total_net_profit DESC;
