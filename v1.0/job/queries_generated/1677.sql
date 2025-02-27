WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
), 
ActorRoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN crt.role = 'Director' THEN 1 ELSE 0 END) AS director_count
    FROM cast_info ci
    JOIN role_type crt ON ci.role_id = crt.id
    GROUP BY ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    COALESCE(mk.keywords, 'No Keywords') AS associated_keywords,
    ar.actor_count,
    ar.director_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
JOIN 
    ActorRoleCounts ar ON rm.movie_id = ar.movie_id
WHERE 
    ar.actor_count > 0
    AND rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC,
    rm.title_rank ASC;
