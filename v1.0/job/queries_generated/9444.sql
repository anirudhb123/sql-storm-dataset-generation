WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT a.name) AS actors
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    rm.actors,
    COALESCE(mk.keywords, '{}') AS keywords
FROM 
    RankedMovies AS rm
LEFT JOIN 
    MovieKeywords AS mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.actor_count DESC, rm.production_year ASC
LIMIT 10;
