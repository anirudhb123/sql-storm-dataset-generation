
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    fc.cast_count,
    mc.company_names
FROM 
    RankedTitles rt
JOIN 
    FilteredCast fc ON rt.title_id = fc.movie_id
LEFT JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC
LIMIT 50;
