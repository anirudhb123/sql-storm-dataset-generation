WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        mc.note LIKE '%blockbuster%'
    
    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(ci.person_id) AS actor_count,
    AVG(pi.info) AS avg_info_length,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY actor_count DESC) AS actor_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    mh.level <= 2 
    AND (pi.info IS NULL OR LENGTH(pi.info) > 5)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(ci.person_id) >= 5
ORDER BY 
    mh.production_year DESC, actor_count DESC;
