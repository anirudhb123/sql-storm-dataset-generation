
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.bill_customer_sk, ws.item_sk
), 
TopCustomerSales AS (
    SELECT 
        st.bill_customer_sk,
        st.item_sk,
        st.total_sales,
        DENSE_RANK() OVER (ORDER BY st.total_sales DESC) AS sales_rank
    FROM 
        SalesCTE st
    WHERE 
        st.sales_rank <= 5
), 
CustomerDemographicsCTE AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unknown'
            ELSE cd.cd_credit_rating
        END AS credit_rating,
        COUNT(td.bill_customer_sk) AS purchase_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        web_sales wd ON cd.cd_demo_sk = wd.bill_cdemo_sk
    LEFT JOIN 
        TopCustomerSales tcs ON wd.item_sk = tcs.item_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, credit_rating
)
SELECT 
    tcs.bill_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.credit_rating,
    SUM(CASE 
        WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_quantity 
        ELSE 0 
    END) AS total_quantity,
    COUNT(ws.ws_order_number) FILTER (WHERE ws.ws_item_sk IS NOT NULL) AS total_orders,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_revenue,
    STRING_AGG(DISTINCT i.brand) AS brands_purchased
FROM 
    TopCustomerSales tcs
LEFT JOIN 
    web_sales ws ON tcs.bill_customer_sk = ws.bill_customer_sk AND tcs.item_sk = ws.ws_item_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
JOIN 
    CustomerDemographicsCTE cd ON tcs.bill_customer_sk = cd.cd_demo_sk
GROUP BY 
    tcs.bill_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.credit_rating
HAVING 
    total_orders > 1 AND total_revenue > 100
ORDER BY 
    total_revenue DESC;
