WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS MovieTitle,
    m.production_year AS ProductionYear,
    a.name AS ActorName,
    COALESCE(k.keyword, 'No Keywords') AS Keyword,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS ActorRank,
    AVG(pi.info) OVER (PARTITION BY m.id) AS AverageRating
FROM 
    MovieHierarchy AS m
LEFT JOIN 
    cast_info AS c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name AS a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info AS mi ON m.movie_id = mi.movie_id 
LEFT JOIN 
    info_type AS it ON mi.info_type_id = it.id 
LEFT JOIN 
    person_info AS pi ON c.person_id = pi.person_id
WHERE 
    m.production_year >= 2000
    AND (it.info IS NULL OR it.info LIKE '%rating%')
ORDER BY 
    m.production_year DESC, m.title;

This query constructs a recursive common table expression to manage relationships in a movie hierarchy, enabling analysis of links between movies such as sequels or shared universes. It filters to include movies only from the year 2000 onwards and utilizes several JOINS to aggregate actor names, keywords, and average ratings. The final result includes performers and provides insights into their cumulative performance using window functions for ranking and calculating averages. The use cases of COALESCE ensures meaningful results in scenarios where data may be missing.
