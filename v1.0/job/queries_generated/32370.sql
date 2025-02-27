WITH RECURSIVE ActorHierarchy AS (
    SELECT ci.person_id, ci.movie_id, 1 AS level
    FROM cast_info ci
    WHERE ci.role_id IN (SELECT id FROM role_type WHERE role = 'Director')

    UNION ALL

    SELECT ci.person_id, ci.movie_id, ah.level + 1
    FROM cast_info ci
    INNER JOIN ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE ci.person_id <> ah.person_id
)

, MovieInfoCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(y2.production_year, 0) AS production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        MAX(mk.keyword) AS last_keyword
    FROM title m
    LEFT JOIN aka_title at ON at.movie_id = m.id
    LEFT JOIN cast_info ci ON ci.movie_id = m.id
    LEFT JOIN movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN movie_info mi ON mi.movie_id = m.id
    LEFT JOIN (
        SELECT movie_id, MAX(production_year) AS production_year 
        FROM aka_title 
        GROUP BY movie_id
    ) y2 ON y2.movie_id = m.id
    GROUP BY m.id, m.title
),

DistinctDirectorMovies AS (
    SELECT DISTINCT a.movie_id
    FROM ActorHierarchy a
)

SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.actor_count,
    mi.company_count,
    mi.keyword_count,
    COALESCE(b.name, 'Unknown') AS best_actor_name,
    COALESCE(directors.movie_id, 0) AS director_movies_count
FROM MovieInfoCTE mi
LEFT JOIN (
    SELECT 
        ci.movie_id,
        ak.name 
    FROM cast_info ci
    JOIN aka_name ak ON ak.person_id = ci.person_id
    WHERE ci.nr_order = 1
) b ON b.movie_id = mi.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(*) AS movie_count
    FROM DistinctDirectorMovies
    GROUP BY movie_id
) directors ON directors.movie_id = mi.movie_id
WHERE mi.production_year > 2000 
  AND (mi.actor_count > 5 OR mi.company_count > 3)
ORDER BY mi.production_year DESC, mi.actor_count DESC;
