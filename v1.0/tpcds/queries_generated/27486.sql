
WITH ItemExtended AS (
    SELECT 
        i.i_item_sk,
        LOWER(i.i_item_desc) AS item_description,
        i.i_current_price,
        SUBSTRING_INDEX(SUBSTRING_INDEX(i.i_item_desc, ' ', 1), ' ', -1) AS first_word,
        SUBSTRING_INDEX(i.i_item_desc, ' ', -1) AS last_word,
        CHAR_LENGTH(i.i_item_desc) AS description_length
    FROM 
        item i
), 
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
ItemSalesDetails AS (
    SELECT 
        ie.i_item_sk,
        ie.item_description,
        ie.i_current_price,
        COALESCE(sd.total_quantity, 0) AS total_quantity,
        COALESCE(sd.total_net_profit, 0) AS total_net_profit
    FROM 
        ItemExtended ie
    LEFT JOIN 
        SalesData sd ON ie.i_item_sk = sd.ws_item_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_education_status,
    isd.item_description,
    isd.i_current_price,
    isd.total_quantity,
    isd.total_net_profit,
    LENGTH(isd.item_description) AS char_count,
    CONCAT(isd.first_word, '...', isd.last_word) AS brief_description
FROM 
    CustomerDemographics cs
JOIN 
    ItemSalesDetails isd ON ISD.total_quantity > 0
WHERE 
    cs.cd_gender = 'F'
ORDER BY 
    isd.total_net_profit DESC, cs.c_last_name ASC
LIMIT 100;
