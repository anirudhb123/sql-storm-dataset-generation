WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM title t
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id,
        title.title AS movie_title,
        title.production_year,
        m.linked_movie_id AS parent_movie_id,
        level + 1
    FROM movie_link m
    JOIN title ON m.linked_movie_id = title.id
    JOIN movie_hierarchy mh ON mh.movie_id = m.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.parent_movie_id,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    AVG(CASE WHEN p.gender IS NULL THEN 0 ELSE 1 END) AS male_actor_ratio,
    SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_actors_count,
    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_actors_count,
    COALESCE(SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_available_count
FROM 
    movie_hierarchy mh
LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
LEFT JOIN person_info p ON ci.person_id = p.person_id
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, 
    mh.movie_title, 
    mh.production_year, 
    mh.parent_movie_id,
    mh.level
ORDER BY 
    mh.level, 
    mh.production_year DESC;

This SQL query creates a recursive CTE, `movie_hierarchy`, to build a structure of movies relating to one another through their links. After establishing the hierarchy, it aggregates actor data for each movie, showcasing fun metrics like the total number of actors, names, gender ratios, and the availability of movie-related information. The result is sorted by the production level and year, providing an insightful benchmark for analyzing movie data with complex relationships.
