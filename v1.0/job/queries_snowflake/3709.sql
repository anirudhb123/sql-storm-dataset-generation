WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        r.role,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        SUM(CASE WHEN ca.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    LEFT JOIN 
        role_type r ON ca.role_id = r.id
    WHERE 
        t.production_year >= 2000 
        AND (c.country_code IS NULL OR c.country_code <> 'USA')
    GROUP BY 
        t.id, t.title, t.production_year, c.name, r.role
),
RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC, note_count DESC) AS rn
    FROM 
        MovieDetails
)
SELECT 
    title_id,
    title,
    production_year,
    company_name,
    role,
    cast_count,
    note_count
FROM 
    RankedMovies
WHERE 
    rn <= 5 
ORDER BY 
    production_year DESC, cast_count DESC;
