WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_details
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        it.info ILIKE '%plot%'
    GROUP BY 
        m.movie_id
),
AggregateGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    a.name,
    rt.title,
    rt.production_year,
    mi.movie_details,
    ag.genres,
    COUNT(ci.movie_id) AS total_cast,
    MAX(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    RankedTitles rt ON ci.movie_id = rt.title_id
LEFT JOIN 
    MovieInfo mi ON rt.title_id = mi.movie_id
LEFT JOIN 
    AggregateGenres ag ON rt.title_id = ag.movie_id
WHERE 
    a.name IS NOT NULL AND 
    (a.name LIKE 'A%' OR a.name LIKE 'B%')
GROUP BY 
    a.name, rt.title, rt.production_year, mi.movie_details, ag.genres
HAVING 
    COUNT(ci.movie_id) > 1
ORDER BY 
    rt.production_year DESC, a.name;
