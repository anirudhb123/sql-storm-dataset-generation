WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
        mt.episode_of_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
        mt.episode_of_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT cc.subject_id) AS character_count,
    LISTAGG(DISTINCT char.name, ', ') AS characters,
    AVG(COALESCE(mk.keyword_count, 0)) AS average_keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT cc.subject_id) DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    complete_cast cc ON mt.movie_id = cc.movie_id
LEFT JOIN 
    (SELECT 
         mk.movie_id, 
         COUNT(mk.keyword_id) AS keyword_count 
     FROM 
         movie_keyword mk 
     GROUP BY 
         mk.movie_id) AS mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    char_name char ON cc.subject_id = char.id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year IS NOT NULL
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT cc.subject_id) > 0
ORDER BY 
    actor_rank, movie_title;


