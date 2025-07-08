
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.episode_of_id, mt.id) AS related_movie_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.episode_of_id, mt.id) AS related_movie_id,
        mh.level + 1 AS level
    FROM
        aka_title mt
    INNER JOIN movie_hierarchy mh ON mt.episode_of_id = mh.movie_id 
)
SELECT
    ma.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year,
    COUNT(DISTINCT mvh.related_movie_id) AS related_movies_count,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ma.id ORDER BY mv.production_year DESC) AS rank
FROM
    cast_info ci
JOIN 
    aka_name ma ON ci.person_id = ma.person_id
JOIN 
    movie_hierarchy mvh ON ci.movie_id = mvh.movie_id
JOIN 
    aka_title mv ON mv.id = mvh.movie_id
LEFT JOIN 
    movie_keyword mk ON mv.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mv.production_year IS NOT NULL
    AND ma.name IS NOT NULL
GROUP BY 
    ma.id, ma.name, mv.title, mv.production_year
HAVING 
    COUNT(DISTINCT mvh.related_movie_id) > 1
ORDER BY 
    actor_name,
    rank;
