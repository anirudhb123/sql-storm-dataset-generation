
WITH ProcessedStrings AS (
    SELECT 
        c.c_customer_id,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS CustomerFullName,
        INITCAP(LOWER(c.c_email_address)) AS NormalizedEmail,
        REPLACE(LOWER(REPLACE(c.c_city, ' ', '_')), ' ', '_') AS FormattedCity,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS GenderDescription
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), AggregatedData AS (
    SELECT 
        ps.CustomerFullName,
        COUNT(ps.CustomerFullName) AS NameOccurrence,
        STRING_AGG(ps.NormalizedEmail, ', ') AS AllEmails,
        STRING_AGG(ps.FormattedCity, ', ') AS AllCities,
        STRING_AGG(ps.GenderDescription, ', ') AS AllGenders
    FROM 
        ProcessedStrings ps
    GROUP BY 
        ps.CustomerFullName
)
SELECT 
    AVG(NameOccurrence) AS AvgNameOccurrence,
    MAX(LENGTH(AllEmails)) AS MaxEmailLength,
    MAX(LENGTH(AllCities)) AS MaxCityLength,
    MAX(LENGTH(AllGenders)) AS MaxGenderLength
FROM 
    AggregatedData
WHERE 
    LENGTH(CustomerFullName) > 0;
