WITH RecursiveCTE AS (
    SELECT 
        ak.name AS aka_name,
        t.title AS title,
        t.production_year AS year,
        c.role_id AS cast_role,
        ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name ak
        JOIN cast_info c ON ak.person_id = c.person_id
        JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE 
        ak.name IS NOT NULL
),
FormattedResults AS (
    SELECT 
        CONCAT(r.rank, ': ', r.aka_name, ' appeared in "', r.title, '" (', r.year, ') with role ID: ', r.cast_role) AS formatted_output
    FROM 
        RecursiveCTE r
    WHERE 
        r.rank <= 5
)
SELECT 
    formatted_output
FROM 
    FormattedResults
ORDER BY 
    CAST(SUBSTRING(formatted_output FROM '(\d+):') AS INTEGER), year DESC;
