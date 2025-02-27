WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        1 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year >= 2000
    UNION ALL
    SELECT 
        cc.id AS cast_id,
        cc.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        ah.depth + 1 
    FROM cast_info cc
    JOIN ActorHierarchy ah ON cc.movie_id IN (
        SELECT m.movie_id FROM movie_link ml 
        JOIN title m ON ml.linked_movie_id = m.id 
        WHERE ml.movie_id = ah.movie_id
    )
    JOIN aka_name a ON cc.person_id = a.person_id
    JOIN aka_title t ON cc.movie_id = t.movie_id
    WHERE ah.depth < 5
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count
    FROM aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    WHERE m.production_year BETWEEN 2000 AND 2020
    GROUP BY m.id, m.title, m.production_year
    HAVING COUNT(c.id) > 5
),
ActorMetrics AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS distinct_movies,
        AVG(depth) AS avg_cast_depth
    FROM ActorHierarchy
    GROUP BY actor_name
),
KeywordStats AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM keyword k
    JOIN movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY k.keyword
    HAVING COUNT(mk.movie_id) > 10
)
SELECT 
    f.title AS movie_title,
    f.production_year,
    f.cast_count,
    a.actor_name,
    COALESCE(k.keyword, 'No Keywords') AS most_used_keyword,
    COALESCE(a.distinct_movies, 0) AS movies_called,
    ROUND(a.avg_cast_depth, 2) AS average_cast_depth
FROM FilteredMovies f
LEFT JOIN ActorMetrics a ON f.cast_count = a.distinct_movies
LEFT JOIN KeywordStats k ON f.movie_id IN (
    SELECT mk.movie_id FROM movie_keyword mk
    WHERE mk.movie_id = f.movie_id
)
ORDER BY f.production_year DESC, f.cast_count DESC
LIMIT 100;
