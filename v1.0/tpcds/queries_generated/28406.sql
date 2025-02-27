
WITH RECURSIVE AddressParts AS (
    SELECT
        ca_address_sk,
        TRIM(SUBSTRING_INDEX(ca_street_name, ' ', 1)) AS street_name_part,
        SUBSTRING_INDEX(SUBSTRING_INDEX(ca_street_name, ' ', -2), ' ', 1) AS street_type_part,
        CHAR_LENGTH(ca_street_name) - CHAR_LENGTH(REPLACE(ca_street_name, ' ', '')) AS space_count
    FROM
        customer_address
),
ProcessedAddresses AS (
    SELECT
        ca_address_sk,
        CONCAT(street_name_part, ' ', street_type_part) AS processed_address,
        space_count
    FROM
        AddressParts
    WHERE
        space_count > 1
),
FinalAddress AS (
    SELECT
        ca_address_sk,
        processed_address,
        CASE
            WHEN space_count = 2 THEN 'Short Address'
            WHEN space_count BETWEEN 3 AND 5 THEN 'Medium Address'
            ELSE 'Long Address'
        END AS address_length_category
    FROM
        ProcessedAddresses
)

SELECT
    fa.address_length_category,
    COUNT(*) AS address_count,
    MIN(ca_address_sk) AS min_address_sk,
    MAX(ca_address_sk) AS max_address_sk,
    AVG(space_count) AS avg_space_count
FROM
    FinalAddress fa
JOIN
    customer_address ca ON fa.ca_address_sk = ca.ca_address_sk
GROUP BY
    fa.address_length_category
ORDER BY
    address_length_category;
