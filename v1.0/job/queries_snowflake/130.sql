
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
HighActorMovies AS (
    SELECT 
        c.movie_id
    FROM ActorCounts c
    WHERE c.actor_count > 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(ham.movie_id, NULL) AS high_actor_movie_id,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM RankedTitles rt
LEFT JOIN HighActorMovies ham ON rt.title_id = ham.movie_id
LEFT JOIN MovieKeywords mk ON rt.title_id = mk.movie_id
WHERE rt.title_rank = 1
ORDER BY rt.production_year DESC, rt.title;
