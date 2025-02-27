WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieCast AS (
    SELECT 
        ci.movie_id,
        mk.keyword,
        c.name AS person_name,
        rc.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY c.name) AS cast_rank
    FROM 
        cast_info ci
    JOIN 
        name c ON ci.person_id = c.id
    JOIN 
        role_type rc ON ci.role_id = rc.id
    JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    mc.person_name,
    mc.role_name,
    mc.keyword
FROM 
    RankedTitles rt
JOIN 
    MovieCast mc ON rt.title_id = mc.movie_id
WHERE 
    rt.year_rank <= 5
    AND mc.cast_rank <= 3
ORDER BY 
    rt.production_year DESC, 
    rt.title;
