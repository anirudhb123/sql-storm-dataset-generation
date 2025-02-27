WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
ActorsWithNotes AS (
    SELECT 
        ak.person_id, 
        ak.name, 
        COALESCE(ci.note, 'No role assigned') AS note,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS role_rank
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
),
MoviesWithKeywords AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    awn.name AS actor_name,
    awn.note AS role_note,
    M.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsWithNotes awn ON rm.actor_count > 10 AND awn.role_rank < 3
LEFT JOIN 
    MoviesWithKeywords M ON rm.title LIKE '%' || M.keywords || '%' OR M.keywords IS NULL
WHERE 
    (rm.rank_within_year = 1 AND rm.production_year > 2000)
    OR (rm.actor_count IS NULL AND rm.production_year < 1990)
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
