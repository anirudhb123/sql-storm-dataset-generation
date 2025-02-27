WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.season_nr,
        mt.episode_nr,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        movie_link.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        a.season_nr,
        a.episode_nr,
        mh.level + 1
    FROM 
        movie_link 
    JOIN 
        aka_title a ON movie_link.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON movie_link.movie_id = mh.movie_id
)

SELECT
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT cc.person_id) AS co_actor_count,
    STRING_AGG(DISTINCT co_ak.name, ', ') AS co_actors,
    AVG(mr.rating) AS average_rating,
    SUM(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END) AS unranked_actors
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id 
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    cast_info cc ON cc.movie_id = c.movie_id AND cc.person_id != ak.person_id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
LEFT JOIN 
    (SELECT movie_id, AVG(CAST(info AS FLOAT)) AS rating FROM movie_info GROUP BY movie_id) mr ON mt.id = mr.movie_id
LEFT JOIN 
    aka_name co_ak ON cc.person_id = co_ak.person_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    actor_name, movie_title, mt.production_year
HAVING 
    COUNT(DISTINCT cc.person_id) > 0
ORDER BY 
    average_rating DESC, movie_title;
