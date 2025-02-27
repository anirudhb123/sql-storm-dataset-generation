WITH FilteredParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_type,
        p_retailprice,
        LENGTH(p_name) AS name_length,
        UPPER(p_brand) AS brand_upper
    FROM 
        part
    WHERE 
        p_retailprice > (SELECT AVG(p_retailprice) FROM part)
), AggregatedData AS (
    SELECT 
        p_type,
        COUNT(*) AS part_count,
        AVG(p_retailprice) AS avg_price,
        SUM(name_length) AS total_name_length,
        STRING_AGG(brand_upper, ', ') AS unique_brands
    FROM 
        FilteredParts
    GROUP BY 
        p_type
)
SELECT 
    p_type,
    part_count,
    avg_price,
    total_name_length,
    unique_brands,
    CONCAT('Type: ', p_type, ' - Total Parts: ', part_count, '; Average Price: ', avg_price, '; Total Name Length: ', total_name_length) AS summary
FROM 
    AggregatedData
ORDER BY 
    avg_price DESC;
