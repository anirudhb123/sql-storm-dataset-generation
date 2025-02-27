WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keyword'),
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.episode_of_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
)

SELECT 
    p.name AS person_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.title, ', ') WITHIN GROUP (ORDER BY mh.production_year DESC) AS movies_list,
    AVG(CASE 
            WHEN c.note IS NOT NULL THEN 1 
            ELSE 0 
        END) AS avg_note_present,
    ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
FROM 
    aka_name p
JOIN 
    cast_info c ON p.person_id = c.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
WHERE 
    p.name IS NOT NULL 
    AND mh.keyword IS NOT NULL 
GROUP BY 
    p.id
HAVING 
    COUNT(DISTINCT c.movie_id) > 0
ORDER BY 
    total_movies DESC;

This query uses:
- A recursive CTE to create a hierarchy of movies and their keywords based on episodes and seasons.
- Joins across multiple tables to gather the names of actors and their movie information.
- Aggregation functions (COUNT, AVG, STRING_AGG) to summarize data.
- NULL handling with the COALESCE function and conditional expressions.
- A window function to rank actors based on their movie counts.
- A complex HAVING clause to ensure that only actors who have appeared in more than zero movies are listed.
