WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        mt.movie_id,
        mt.company_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mt
    JOIN 
        company_name cn ON mt.company_id = cn.id
    JOIN 
        company_type ct ON mt.company_type_id = ct.id
    WHERE 
        cn.country_code = 'USA'
        AND ct.kind <> 'Distributor'
)
SELECT 
    COALESCE(ka.name, 'Unknown') AS actor_name, 
    tt.title,
    tt.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(tt.year_rank) OVER (PARTITION BY tt.production_year) AS avg_rank
FROM 
    aka_name ka
LEFT JOIN 
    cast_info ci ON ka.person_id = ci.person_id
LEFT JOIN 
    RankedTitles tt ON ci.movie_id = tt.title_id
LEFT JOIN 
    FilteredMovies mc ON tt.title_id = mc.movie_id
WHERE 
    tt.production_year >= 2000
    AND (ka.name IS NOT NULL OR ci.note LIKE '%featured%')
GROUP BY 
    ka.name, tt.title, tt.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    avg_rank DESC, actor_name;
