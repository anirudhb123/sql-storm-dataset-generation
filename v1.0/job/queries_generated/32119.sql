WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- base case

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ah.person_id,
    ak.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(cd.movie_id) AS total_movies,
    AVG(cd.nr_order) AS average_order,
    STRING_AGG(DISTINCT mt.production_year::TEXT, ', ') AS production_years,
    CASE 
        WHEN COUNT(cd.movie_id) IS NULL THEN 'No movies'
        ELSE 'Movies available'
    END AS movie_availability
FROM 
    cast_info cd
JOIN 
    aka_name ak ON cd.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON cd.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    (SELECT 
        DISTINCT movie_id, 
        COUNT(id) OVER (PARTITION BY movie_id) AS movie_count
     FROM 
        complete_cast) AS cc ON cd.movie_id = cc.movie_id
WHERE 
    cd.nr_order IS NOT NULL
GROUP BY 
    ah.person_id, ak.name, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT mt.id) > 1
ORDER BY 
    COUNT(cd.movie_id) DESC, ak.name;

This query uses a recursive CTE `movie_hierarchy` to create a hierarchy of movies linked together via a `movie_link` table. It then retrieves actor names, movie titles, and other calculated metrics such as total movies acted in and the average order of roles using aggregations. The query incorporates outer joins, complex case logic, and string aggregation, all while grouping by relevant identifiers and filtering based on specified criteria.
