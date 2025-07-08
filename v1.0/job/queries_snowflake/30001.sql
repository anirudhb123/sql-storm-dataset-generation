
WITH RECURSIVE ActorHierarchy AS (
    SELECT c.id AS cast_id, c.person_id, c.movie_id, 1 AS level
    FROM cast_info c
    WHERE c.role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%')
    
    UNION ALL
    
    SELECT c.id AS cast_id, c.person_id, c.movie_id, ah.level + 1
    FROM cast_info c
    JOIN ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE c.person_id <> ah.person_id
),
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        y.keyword AS movie_keyword,
        a.name AS actor_name,
        COUNT(ah.cast_id) AS actor_count
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword y ON mk.keyword_id = y.id
    JOIN cast_info c ON t.id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN ActorHierarchy ah ON c.id = ah.cast_id
    WHERE t.production_year >= 2000
    GROUP BY t.title, t.production_year, y.keyword, a.name
),
RankedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.actor_name,
        md.actor_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.actor_count DESC) AS actor_rank
    FROM MovieDetails md
)
SELECT 
    r.production_year,
    LISTAGG(DISTINCT r.movie_title, ', ') AS movies,
    COUNT(DISTINCT r.actor_name) AS distinct_actors,
    SUM(CASE WHEN r.actor_rank <= 3 THEN 1 ELSE 0 END) AS top_3_movies_count
FROM RankedMovies r
WHERE r.actor_count IS NOT NULL
GROUP BY r.production_year
ORDER BY r.production_year DESC;
