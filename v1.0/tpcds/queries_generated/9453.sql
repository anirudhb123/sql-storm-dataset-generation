
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_paid_inc_tax) AS average_order_value,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_sales) AS total_sales_by_demo,
        SUM(sd.total_orders) AS total_orders_by_demo
    FROM 
        SalesData sd
    JOIN 
        customer c ON sd.web_site_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
),
InventoryStatus AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT inv.inv_item_sk) AS unique_items
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
),
PromotionAnalysis AS (
    SELECT 
        p.p_promo_name, 
        SUM(ws.ws_ext_sales_price) AS promo_sales
    FROM 
        web_sales ws 
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        p.p_promo_name
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    is.total_inventory,
    is.unique_items,
    pa.promo_sales,
    sd.total_sales,
    sd.total_orders,
    sd.average_order_value,
    sd.unique_customers
FROM 
    CustomerDemographics cd
JOIN 
    InventoryStatus is ON cd.total_orders_by_demo > 0
JOIN 
    SalesData sd ON cd.total_orders_by_demo > 0
JOIN 
    PromotionAnalysis pa ON sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC;
