WITH RECURSIVE movie_hierarchy AS (
    -- Base case: Select the top-level movies
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    -- Recursive case: Join with the movie_link table to find linked movies
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    COALESCE(CAST(MAX(mk.keyword) AS text), 'No keywords') AS keyword,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY actor_count DESC) AS rank_within_year
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    mh.production_year DESC, actor_count DESC;

This SQL query uses a recursive Common Table Expression (CTE) to build a hierarchy of movies, including those linked to one another through the `movie_link` table. It selects the title and production year of each movie, alongside the count of unique actors involved and a concatenated list of their names. It also includes logic to categorize the movies by era based on their production year. Finally, it ranks movies within each year based on their actor count and filters out movies without actors, ordering the results by production year and actor count.

