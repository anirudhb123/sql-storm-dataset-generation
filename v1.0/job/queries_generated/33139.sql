WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
)

, RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy AS mh
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    ARRAY_AGG(DISTINCT cn.name) AS production_companies,
    AVG(ki_count) filter (WHERE ki_count IS NOT NULL) AS average_keywords,
    MAX(CASE WHEN CAST(cc.nr_order AS INTEGER) IS NULL THEN 0 ELSE cc.nr_order END) AS max_cast_order
FROM 
    RankedMovies AS mt
JOIN 
    complete_cast AS cc ON cc.movie_id = mt.movie_id
JOIN 
    cast_info AS ci ON ci.movie_id = cc.movie_id 
                       AND ci.person_id = cc.subject_id
JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = mt.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = mt.movie_id
LEFT JOIN 
    keyword AS k ON k.id = mk.keyword_id
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT ci.id) > 1
ORDER BY 
    mt.production_year DESC, actor_name;

This query constructs a recursive Common Table Expression (CTE) to create a movie hierarchy starting from movies produced from the year 2000. It joins various tables to gather actor names, movie titles, production companies, and associated keywords. It uses window functions to rank movies while aggregating company names and calculating average keywords. The results filter out movies with only one cast member, ensuring more substantial data is returned, ordered by production year and actor's name.
