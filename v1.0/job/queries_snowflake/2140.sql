
WITH MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyCTE AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.total_cast,
    m.cast_names,
    COALESCE(c.company_name, 'Independent') AS company_name,
    COALESCE(c.company_type, 'N/A') AS company_type,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.total_cast DESC) AS rank
FROM 
    MovieCTE m
LEFT JOIN 
    CompanyCTE c ON m.movie_id = c.movie_id
WHERE 
    m.production_year BETWEEN 1990 AND 2020
ORDER BY 
    m.production_year, rank
LIMIT 100;
