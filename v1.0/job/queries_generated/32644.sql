WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Sequel: ', m.title) AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    COALESCE(a.name, 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    SUM(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level) AS row_num
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, mh.level, a.name
HAVING 
    COUNT(DISTINCT mc.company_id) > 2 AND 
    mh.production_year < (SELECT AVG(production_year) FROM aka_title)
ORDER BY 
    mh.production_year DESC, mh.level ASC;
