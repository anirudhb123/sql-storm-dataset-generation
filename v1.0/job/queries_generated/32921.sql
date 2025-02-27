WITH RECURSIVE ActorHierarchy AS (
    SELECT c.movie_id, c.person_id, 1 AS depth
    FROM cast_info c
    WHERE c.role_id IS NOT NULL  -- Filtering for valid roles

    UNION ALL

    SELECT ci.movie_id, ci.person_id, ah.depth + 1
    FROM cast_info ci
    JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.role_id IS NULL  -- Collecting related roles, if any
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = t.id) AS total_cast,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000 -- Movies from 2000 onwards
),
TopActors AS (
    SELECT 
        ah.person_id,
        COUNT(DISTINCT ah.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM ActorHierarchy ah
    JOIN title t ON t.id = ah.movie_id
    GROUP BY ah.person_id
    HAVING COUNT(DISTINCT ah.movie_id) > 5  -- Only actors with more than 5 movies
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ta.movie_count AS actor_movie_count,
    ta.movies,
    md.keyword,
    md.total_cast,
    md.rank_within_year
FROM MovieDetails md
LEFT JOIN TopActors ta ON ta.person_id IN (
    SELECT ci.person_id
    FROM cast_info ci
    WHERE ci.movie_id = md.movie_id
)
ORDER BY md.production_year DESC, md.title
LIMIT 50;  -- Limit the results to the top 50 movies
