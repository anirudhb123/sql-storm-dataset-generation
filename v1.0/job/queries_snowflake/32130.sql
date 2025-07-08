
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        ARRAY_AGG(ci.movie_id) AS movies,
        1 AS level
    FROM cast_info ci
    WHERE ci.role_id = (SELECT id FROM role_type WHERE role = 'Lead Actor')
    GROUP BY ci.person_id
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        ARRAY_CAT(ah.movies, ARRAY[ci.movie_id]),
        ah.level + 1
    FROM cast_info ci
    JOIN ActorHierarchy ah ON ci.movie_id = ANY(ah.movies)
    WHERE ci.person_id <> ah.person_id
),
RankedTitles AS (
    SELECT 
        a.person_id AS actor_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
)
SELECT 
    ah.person_id, 
    a.name AS actor_name,
    COUNT(DISTINCT rt.movie_title) AS total_movies, 
    MAX(rt.production_year) AS last_movie_year,
    LISTAGG(DISTINCT rt.movie_title, ', ') WITHIN GROUP (ORDER BY rt.rank) AS top_movies,
    LISTAGG(DISTINCT kt.keyword, ', ') AS associated_keywords
FROM ActorHierarchy ah
JOIN aka_name a ON ah.person_id = a.person_id
LEFT JOIN RankedTitles rt ON a.person_id = rt.actor_id
LEFT JOIN movie_keyword mk ON mk.movie_id = ANY(ah.movies)
LEFT JOIN keyword kt ON mk.keyword_id = kt.id
WHERE ah.level <= 2
GROUP BY ah.person_id, a.name
HAVING COUNT(DISTINCT rt.movie_title) > 5
ORDER BY total_movies DESC, last_movie_year DESC;
