
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS sales_count,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_ext_sales_price) > 1000
), CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender, 
        cd_marital_status, 
        cd_education_status, 
        cd_purchase_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 5000
), ItemsWithPromotions AS (
    SELECT 
        i.i_item_sk, 
        i.i_item_id, 
        p.p_promo_name, 
        p.p_cost 
    FROM 
        item i
    JOIN 
        promotion p ON i.i_item_sk = p.p_item_sk 
    WHERE 
        p.p_discount_active = 'Y'
), AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
    SUM(s.total_sales) AS total_sales,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(p.p_cost) AS max_promotion_cost,
    MAX(a.customer_count) AS total_customers
FROM 
    AddressDetails a
LEFT JOIN 
    SalesCTE s ON a.customer_count > 0
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk IN (SELECT c_current_cdemo_sk FROM customer WHERE c_current_addr_sk = a.ca_address_sk)
LEFT JOIN 
    ItemsWithPromotions p ON s.ws_item_sk = p.i_item_sk
GROUP BY 
    a.ca_city, a.ca_state, cd.cd_gender, cd.cd_marital_status
HAVING 
    COUNT(DISTINCT cd.cd_demo_sk) > 0
ORDER BY 
    total_sales DESC, max_promotion_cost DESC
LIMIT 50;
