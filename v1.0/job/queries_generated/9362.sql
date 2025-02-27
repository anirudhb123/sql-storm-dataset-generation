WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aliases,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aliases
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.aliases,
    comp.name AS company_name,
    info.info AS additional_info
FROM 
    PopularMovies pm
JOIN 
    movie_companies mc ON pm.movie_id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    movie_info mi ON pm.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    comp.country_code = 'USA'
ORDER BY 
    pm.cast_count DESC, pm.production_year ASC;
