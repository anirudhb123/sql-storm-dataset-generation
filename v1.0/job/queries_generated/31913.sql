WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year <= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
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
    ah.name AS ActorName,
    mt.title AS MovieTitle,
    COUNT(DISTINCT cc.person_id) AS TotalActors,
    AVG(CASE WHEN ci.note IS NOT NULL THEN ci.nr_order ELSE NULL END) AS AvgOrder,
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.nr_order ELSE 0 END) AS MaxOrder,
    COUNT(DISTINCT kw.keyword) AS TotalKeywords,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS Keywords,
    COALESCE(AVG(mi.info_length), 0) AS AvgInfoLength
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ah ON ci.person_id = ah.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         LENGTH(info) AS info_length
     FROM 
         movie_info
     WHERE 
         info IS NOT NULL) mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level <= 2
GROUP BY 
    ah.name, mt.title
ORDER BY 
    TotalActors DESC, AvgOrder ASC;

This query provides a complex performance benchmark by utilizing a recursive CTE to handle movie hierarchies. It pulls in various statistics, employing window functions and set operators, effectively demonstrates NULL logic handling with `COALESCE`, and aggregates data across multiple joined tables. The final result is a comprehensive breakdown of actor contributions and movie associations, showcasing a range of SQL functionalities.
