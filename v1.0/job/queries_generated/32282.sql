WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Select only movies

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        lt.title AS movie_title,
        lt.production_year,
        mh.level + 1 AS level,
        CAST(mh.path || ' -> ' || lt.title AS VARCHAR(255)) AS path
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title lt ON ml.linked_movie_id = lt.id
    WHERE mh.level < 5  -- Limit hierarchy depth
)

SELECT 
    ak.name AS actor_name,
    tk.title AS movie_title,
    COUNT(DISTINCT cc.id) AS character_count,
    AVG(pi.info::NUMERIC) AS average_rating,  -- Assuming `info` in movie_info holds ratings
    MAX(mh.level) AS max_link_depth,
    STRING_AGG(DISTINCT mh.path, '; ') AS linked_movies
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN title tk ON ci.movie_id = tk.id
LEFT JOIN movie_info mi ON tk.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN MovieHierarchy mh ON tk.id = mh.movie_id
LEFT JOIN char_name cn ON cn.imdb_id = ci.person_role_id -- Join on character info
LEFT JOIN complete_cast cc ON tk.id = cc.movie_id AND cc.subject_id = ak.person_id
WHERE tk.production_year >= 2000  -- Only consider movies from 2000 onward
  AND tk.title IS NOT NULL
GROUP BY ak.name, tk.title
HAVING COUNT(DISTINCT cc.id) > 0
ORDER BY average_rating DESC, actor_name ASC
LIMIT 10;

This SQL query retrieves the names of actors along with the titles of their movies, calculates the average rating of these movies (assuming the ratings are stored in the `info` column of `movie_info`), counts the number of characters each actor has played, and aggregates the paths of linked movies within a maximum depth of 5. The query also incorporates recursive common table expressions (CTEs) to explore relationships between movies using `movie_link`, while filtering for movies produced since the year 2000. The results are ordered by average rating, showing the top 10 actors.
