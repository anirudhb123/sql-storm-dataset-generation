WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    AVG(CASE 
            WHEN ci.nr_order IS NULL THEN 0 
            ELSE ci.nr_order 
        END) AS avg_order,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    (
        SELECT 
            COUNT(*) 
        FROM 
            movie_info mi 
        WHERE 
            mi.movie_id = mh.movie_id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
            AND mi.info IS NOT NULL
    ) AS has_box_office_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, actor_count DESC
LIMIT 10;

This query uses a recursive Common Table Expression (CTE) to create a hierarchy of movies linked together in `movie_link`, retrieves details about actors in these movies using an outer join on `cast_info` and `aka_name`, and calculates counts and averages using window functions and aggregate functions. It also includes a correlated subquery to check for box office information associated with each movie. The results are then sorted to show the most recent movies with the highest actor counts.
