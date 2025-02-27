WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        CONCAT(m.title, ' (Sequel to ', mh.title, ')') AS title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS full_title,
    mh.production_year,
    COALESCE(ka.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT ka.id) OVER (PARTITION BY mh.movie_id) AS unique_actor_count,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = mh.movie_id) AS total_cast,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    SUM(CASE WHEN ki.kind IS NULL THEN 1 ELSE 0 END) AS null_company_types
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ka ON ci.person_id = ka.person_id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type ki ON mc.company_type_id = ki.id
WHERE 
    mh.depth <= 2
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ka.name
HAVING 
    COUNT(ci.id) > 2 OR COUNT(DISTINCT kw.keyword) > 5
ORDER BY 
    mh.production_year DESC, unique_actor_count DESC
LIMIT 50;
