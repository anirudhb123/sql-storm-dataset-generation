
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
        AND ws_sales_price > 0
),
TopProfitableItems AS (
    SELECT 
        r.ws_item_sk, 
        r.ws_sales_price, 
        r.profit_rank
    FROM 
        RankedSales r
    WHERE 
        r.profit_rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        hd.hd_income_band_sk IS NOT NULL
),
FinalAnalysis AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        SUM(CASE WHEN si.ws_item_sk IS NOT NULL THEN 1 ELSE 0 END) AS items_purchased,
        MAX(CASE WHEN si.ws_item_sk IS NOT NULL THEN 1 ELSE 0 END) AS has_purchased,
        SUM(CASE WHEN si.ws_item_sk IN (SELECT ws_item_sk FROM TopProfitableItems) THEN 1 ELSE 0 END) AS purchased_top_items
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN 
        web_sales si ON c.c_customer_sk = si.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT 
    fa.c_customer_sk,
    fa.c_first_name,
    fa.c_last_name,
    fa.return_count,
    fa.total_return_amt,
    fa.items_purchased,
    fa.has_purchased,
    fa.purchased_top_items,
    CASE 
        WHEN fa.return_count > 0 THEN 'High Risk' 
        WHEN fa.items_purchased = 0 THEN 'Inactive' 
        ELSE 'Active' 
    END AS customer_status,
    ROW_NUMBER() OVER (ORDER BY fa.total_return_amt DESC) AS return_rank
FROM 
    FinalAnalysis fa
WHERE 
    EXISTS (SELECT 1 FROM CustomerDemographics cd WHERE cd.cd_demo_sk = fa.c_customer_sk AND cd.cd_gender = 'F')
ORDER BY 
    fa.return_rank
FETCH FIRST 100 ROWS ONLY;
