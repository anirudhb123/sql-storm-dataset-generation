WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mv.title AS movie_title,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(mi.production_year) AS average_production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    COALESCE(cd.note, 'No Notes') AS cast_note,
    CASE 
        WHEN ct.kind = 'Comedy' THEN 'Light & Fun'
        WHEN ct.kind = 'Drama' THEN 'Deep & Emotional'
        ELSE 'Varied Genre'
    END AS genre_description,
    ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY mv.title) AS row_num_by_year
FROM 
    movie_hierarchy mh
JOIN 
    aka_title mv ON mh.movie_id = mv.id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mv.id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    movie_info mi ON mi.movie_id = mv.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mv.id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mv.id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
LEFT JOIN 
    (SELECT movie_id, note 
     FROM complete_cast 
     WHERE status_id IS NOT NULL) cd ON cd.movie_id = mv.id
WHERE 
    mv.production_year > 2000
    AND (mv.title ILIKE '%adventure%' OR mv.title ILIKE '%fantasy%')
GROUP BY 
    mv.title, cd.note, ct.kind
HAVING 
    COUNT(DISTINCT mk.keyword) > 2
ORDER BY 
    row_num_by_year, mv.title;
