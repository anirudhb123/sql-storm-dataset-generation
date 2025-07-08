WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
TopActors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.person_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
), 
ActorsByTitle AS (
    SELECT 
        rm.title,
        rm.production_year,
        ta.actor_name,
        ta.actor_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        TopActors ta ON rm.movie_id = ta.movie_id
    WHERE 
        rm.title_rank <= 5 AND (ta.actor_rank IS NULL OR ta.actor_rank <= 2)
), 
KeywordCounts AS (
    SELECT 
        m.title,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.title
)
SELECT 
    abt.title,
    abt.production_year,
    abt.actor_name,
    COALESCE(kc.keyword_count, 0) AS keyword_count
FROM 
    ActorsByTitle abt
FULL OUTER JOIN 
    KeywordCounts kc ON abt.title = kc.title
WHERE 
    abt.actor_name IS NOT NULL OR kc.keyword_count > 0
ORDER BY 
    abt.production_year DESC, abt.title;