WITH RecursiveMovieData AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ct.kind AS content_type,
        COUNT(DISTINCT cc.person_id) AS total_cast_members,
        SUM(CASE WHEN longest_name_length > 0 THEN 1 ELSE 0 END) AS long_name_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info cc ON cc.movie_id = t.movie_id
    JOIN 
        kind_type ct ON ct.id = t.kind_id
    LEFT JOIN (
        SELECT 
            person_id, 
            MAX(LENGTH(name)) AS longest_name_length
        FROM 
            aka_name 
        GROUP BY 
            person_id
    ) an ON an.person_id = cc.person_id
    GROUP BY 
        t.id, t.title, t.production_year, ct.kind
    HAVING 
        COUNT(DISTINCT cc.person_id) > 0
),
MovieCompanies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.title, 
    m.production_year,
    COALESCE(m.total_cast_members, 0) AS total_cast,
    COALESCE(mc.company_names, 'No Companies') AS companies,
    COALESCE(mc.total_companies, 0) AS total_companies,
    CASE 
        WHEN m.long_name_count > 0 THEN 'Contains Long Names'
        ELSE 'No Long Names'
    END AS long_name_status,
    CASE
        WHEN m.production_year IS NULL THEN 'Year Unknown'
        WHEN m.production_year > 2000 THEN 'Modern Era'
        ELSE 'Classic Era'
    END AS era_category
FROM 
    RecursiveMovieData m
FULL OUTER JOIN 
    MovieCompanies mc ON m.title_id = mc.movie_id
WHERE 
    (m.total_cast_members IS NOT NULL OR mc.total_companies > 0)
AND 
    (m.production_year BETWEEN 1970 AND 2023 OR mc.total_companies > 2)
ORDER BY 
    m.production_year DESC NULLS LAST, 
    m.title ASC;
