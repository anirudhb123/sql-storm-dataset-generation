WITH RECURSIVE MovieHierarchy AS (
    SELECT t.id, t.title, t.production_year, 0 AS level
    FROM aka_title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT t.id, t.title, t.production_year, mh.level + 1
    FROM aka_title t
    JOIN MovieHierarchy mh ON t.episode_of_id = mh.id
),
ActorCount AS (
    SELECT c.movie_id, COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
MovieInfo AS (
    SELECT m.id AS movie_id, m.title, m.production_year, COALESCE(ai.actor_count, 0) AS actor_count
    FROM aka_title m
    LEFT JOIN ActorCount ai ON m.id = ai.movie_id
),
KeywordDetails AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompleteMovieInfo AS (
    SELECT mi.movie_id, mi.title, mi.production_year, mi.actor_count, kd.keywords
    FROM MovieInfo mi
    LEFT JOIN KeywordDetails kd ON mi.movie_id = kd.movie_id
),
YearStats AS (
    SELECT production_year,
           AVG(actor_count) AS avg_actors,
           COUNT(*) AS movie_count
    FROM CompleteMovieInfo
    GROUP BY production_year
)

SELECT cm.movie_id,
       cm.title,
       cm.production_year,
       cm.actor_count,
       COALESCE(kd.keywords, 'No keywords') AS keywords,
       ys.avg_actors,
       ys.movie_count
FROM CompleteMovieInfo cm
JOIN YearStats ys ON cm.production_year = ys.production_year
LEFT JOIN aka_name an ON an.person_id IN (
        SELECT c.person_id
        FROM cast_info c
        WHERE c.movie_id = cm.movie_id
)
WHERE cm.actor_count > 0
  AND cm.production_year IS NOT NULL
ORDER BY cm.production_year DESC, cm.actor_count DESC;
