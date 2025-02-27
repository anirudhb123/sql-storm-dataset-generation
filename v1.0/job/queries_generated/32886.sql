WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(tt.title, 'N/A') AS parent_title,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        aka_title tt ON m.episode_of_id = tt.id

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.parent_title,
        ROW_NUMBER() OVER (PARTITION BY mh.parent_title ORDER BY mh.production_year DESC) AS rn
    FROM 
        movie_hierarchy mh
)
SELECT 
    a.name AS actor_name,
    COALESCE(mh.title, 'Unknown Title') AS movie_title,
    mh.production_year,
    r.rn AS movie_rank,
    COUNT(DISTINCT kc.id) AS unique_keywords,
    AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS average_movie_info
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    ranked_movies mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year > 2000
    AND (a.name ILIKE '%Smith%' OR a.name ILIKE '%Doe%')
GROUP BY 
    a.name, mh.title, mh.production_year, r.rn
HAVING 
    COUNT(DISTINCT kc.id) > 2
ORDER BY 
    actor_name, production_year DESC;

This query utilizes several constructs:
- A recursive CTE (`movie_hierarchy`) to generate a hierarchy of movies and episodes.
- A ranking of movies based on the production year within each episode series in `ranked_movies`.
- Joins across multiple tables: `cast_info`, `aka_name`, `ranked_movies`, `movie_keyword`, `keyword`, and `movie_info`.
- A complex WHERE clause with string expressions to filter actor names.
- An aggregation of keywords and movie info status, with meaningful groupings and filtering in the HAVING clause. 
- Result sorting by actor name and the production year in descending order to prioritize newer works.
