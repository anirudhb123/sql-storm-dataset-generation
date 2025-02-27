WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.imdb_id,
        mt.episode_of_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')      -- Base case: select movies

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.imdb_id,
        mt.episode_of_id,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.id          -- Recursive case: join on episodes
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    a.name AS actor_name,
    a.imdb_index AS actor_index,
    COUNT(DISTINCT kc.keyword) AS number_of_keywords,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords_list,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS keyword_rank,
    COALESCE(NULLIF(a.md5sum, ''), 'UNKNOWN') AS actor_md5
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword kc ON kc.id = mk.keyword_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    m.title, m.production_year, a.name, a.imdb_index, a.md5sum
HAVING 
    COUNT(DISTINCT kc.keyword) > 5
ORDER BY 
    m.production_year DESC, keyword_rank;
