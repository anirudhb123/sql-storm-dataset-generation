WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id, 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_by_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_year <= 5
)
SELECT 
    tm.title AS top_movie_title,
    a.name AS actor_name,
    COUNT(cc.id) AS total_cast,
    COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS num_roles,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON cc.movie_id = tm.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword kt ON kt.id = mk.keyword_id
WHERE 
    tm.production_year >= 2000
GROUP BY 
    tm.movie_id, tm.title, a.name
HAVING 
    COUNT(cc.id) > 2
ORDER BY 
    tm.production_year DESC, num_roles DESC;
