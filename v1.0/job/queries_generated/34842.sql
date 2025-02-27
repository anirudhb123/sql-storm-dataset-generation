WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        lm.linked_movie_id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.depth + 1
    FROM 
        movie_link lm
    JOIN 
        aka_title mt ON lm.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON lm.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    title.movie_title,
    title.production_year,
    COUNT(DISTINCT cc.person_id) AS num_cast_members,
    AVG(CASE 
        WHEN title.production_year IS NULL THEN NULL 
        ELSE EXTRACT(YEAR FROM CURRENT_DATE) - title.production_year 
    END) AS avg_movie_age,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords
FROM 
    actor_info AS a
LEFT JOIN 
    cast_info AS cc ON a.id = cc.person_id
LEFT JOIN 
    MovieHierarchy title ON cc.movie_id = title.movie_id
LEFT JOIN 
    movie_keyword mk ON title.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    (title.production_year IS NOT NULL OR cc.movie_id IS NULL)
AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, title.movie_title, title.production_year
HAVING 
    COUNT(DISTINCT cc.person_id) > 2
ORDER BY 
    avg_movie_age DESC, num_cast_members DESC;

This query does the following:
1. It defines a recursive CTE `MovieHierarchy` to build a hierarchy of movies linked to each other.
2. It selects actor names, their movies, and important metrics such as the number of cast members and average movie age.
3. It uses a LEFT JOIN to include all actors, even if they have no associated movies.
4. It aggregates associated keywords related to the movies into a single string.
5. It filters out entries with no associated production year and counts only those actors with more than two cast roles.
6. The results are ordered by the average age of movies in descending order, followed by the number of cast members in descending order.
