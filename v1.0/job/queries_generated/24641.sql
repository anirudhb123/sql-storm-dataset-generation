WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_nr,
        COALESCE(mt.episode_nr, 0) AS episode_nr,
        1 AS hierarchy_level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(m.season_nr, 0),
        COALESCE(m.episode_nr, 0),
        mh.hierarchy_level + 1
    FROM 
        aka_title m 
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    ch.name AS character_name,
    COUNT(m.id) AS total_movies,
    SUM(CASE WHEN m.production_year IS NOT NULL THEN 1 ELSE 0 END) AS valid_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_associated,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(m.id) DESC) AS actor_rank,
    COUNT(DISTINCT mt.season_nr) AS seasons_participated,
    COALESCE(NULLIF(MAX(mt.production_year), 0), 'Unknown Year') AS last_movie_year,
    CASE 
        WHEN COUNT(m.id) > 5 THEN TRUE 
        ELSE FALSE 
    END AS prolific_actor
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    char_name ch ON ci.role_id = ch.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    (SELECT movie_id, production_year 
     FROM movie_info 
     WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Production Year')) mi 
    ON mt.id = mi.movie_id
LEFT JOIN 
    movie_hierarchy m ON m.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mt.title, ch.name
HAVING 
    COUNT(m.id) > 0 AND SUM(m.production_year) > 1000
ORDER BY 
    total_movies DESC, last_movie_year DESC
LIMIT 10 OFFSET 5;
