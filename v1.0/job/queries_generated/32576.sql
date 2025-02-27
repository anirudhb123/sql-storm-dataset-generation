WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    
    UNION ALL
    
    SELECT 
        mk.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        mh.level + 1 AS level
    FROM 
        movie_link mk
    INNER JOIN MovieHierarchy mh ON mk.movie_id = mh.movie_id
    INNER JOIN aka_title mt ON mk.linked_movie_id = mt.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.keyword,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order,
    COUNT(DISTINCT mi.info_type_id) AS info_count,
    STRING_AGG(DISTINCT ci.note, ', ') AS actor_notes,
    STRING_AGG(DISTINCT p.name, ', ') AS actor_names,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_actors
FROM 
    MovieHierarchy mh
LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN person_info pi ON ci.person_id = pi.person_id
LEFT JOIN aka_name p ON pi.person_id = p.person_id AND p.name IS NOT NULL
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year >= 2000
    AND mh.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short'))
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.keyword
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    mh.production_year, total_actors DESC;

This SQL query constructs a recursive Common Table Expression (CTE) named `MovieHierarchy` to explore relationships between movies and their linked titles. It collects relevant information like keywords and aggregates actor data alongside movie information, allowing for performance insights and showcasing the use of aggregate functions, string aggregation, window functions, and subqueries. The final result is filtered and sorted to provide a ranked list of movies based on various criteria.
