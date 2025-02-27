WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1 AS level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COALESCE(mci.note, 'No details') AS company_note,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN kw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    ROW_NUMBER() OVER(PARTITION BY ak.person_id ORDER BY mh.production_year DESC) AS recent_movie_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
LEFT JOIN 
    movie_info_idx mii ON mii.movie_id = mh.movie_id AND mii.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
LEFT JOIN 
    movie_info mi2 ON mh.movie_id = mi2.movie_id AND mi2.note IS NOT NULL
LEFT JOIN 
    (SELECT DISTINCT movie_id, note FROM movie_companies WHERE note IS NOT NULL) mci ON mh.movie_id = mci.movie_id
WHERE 
    mh.level <= 3
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, at.title, mh.production_year, mci.note
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    recent_movie_rank, mh.production_year DESC;
