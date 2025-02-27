
WITH AddressSegments AS (
    SELECT
        ca_address_sk,
        TRIM(SUBSTRING_INDEX(ca_street_name, ' ', 1)) AS first_word,
        TRIM(SUBSTRING_INDEX(ca_street_name, ' ', -1)) AS last_word,
        LENGTH(ca_street_name) - LENGTH(REPLACE(ca_street_name, ' ', '')) + 1 AS word_count
    FROM
        customer_address
),
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
ItemStatistics AS (
    SELECT
        i_brand,
        COUNT(i_item_sk) AS total_items,
        AVG(i_current_price) AS avg_price,
        SUM(CASE WHEN i_size IS NOT NULL THEN 1 ELSE 0 END) AS size_specified_count
    FROM
        item
    GROUP BY
        i_brand
),
FinalBenchmark AS (
    SELECT 
        a.ca_address_sk,
        a.first_word,
        a.last_word,
        a.word_count,
        d.cd_gender,
        d.customer_count,
        d.avg_purchase_estimate,
        d.total_dependents,
        i.i_brand,
        i.total_items,
        i.avg_price,
        i.size_specified_count
    FROM 
        AddressSegments a
    JOIN 
        DemographicStats d ON a.ca_address_sk % 2 = 0  -- Randomly pairing data for demonstration
    JOIN 
        ItemStatistics i ON a.ca_address_sk % 3 = 0  -- Randomly pairing data for demonstration
)
SELECT 
    *
FROM 
    FinalBenchmark
WHERE 
    total_dependents > 3 
ORDER BY 
    avg_price DESC, customer_count ASC;
