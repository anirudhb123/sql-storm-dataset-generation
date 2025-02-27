WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    COALESCE(NULLIF(a.name, ''), 'Unknown Actor') AS actor_name,
    COUNT(DISTINCT cc.person_id) OVER (PARTITION BY t.id) AS actor_count,
    MAX(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice') 
        THEN mi.info 
        ELSE NULL 
    END) AS box_office,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COUNT(DISTINCT mh.linked_movie_id) AS linked_movies,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
FROM 
    title t
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    aka_name a ON a.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = t.id)
LEFT JOIN 
    complete_cast cc ON cc.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    MovieHierarchy mh ON mh.movie_id = t.id
WHERE 
    t.production_year IS NOT NULL
    AND (t.production_year >= 2000 OR t.production_year IS NULL)
    AND (cn.country_code IS NOT NULL OR t.title LIKE '%Fantastic%')
GROUP BY 
    t.id, a.name
ORDER BY 
    actor_count DESC, movie_title
LIMIT 50;
