WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IS NOT NULL AND mt.production_year IS NOT NULL

    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', at.title)
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    ARRAY_AGG(DISTINCT CASE WHEN mk.keyword IS NOT NULL THEN mk.keyword END) AS keywords,
    STRING_AGG(DISTINCT COALESCE(info.info, 'No Info'), ', ') AS movie_info,
    MAX(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN mi.info 
        ELSE NULL END) AS budget,
    MAX(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN mi.info 
        ELSE NULL END) AS rating,
    COUNT(DISTINCT mh.movie_id) AS linkage_level,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY SUM(COALESCE(mi.info::INTEGER, 0)) DESC) AS info_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL AND ak.name <> ''
    AND mt.production_year >= 2000
GROUP BY 
    ak.name, mt.title
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    info_rank, COUNT(DISTINCT mc.company_id) DESC
LIMIT 100;
