WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        0 AS level,
        mt.id AS movie_id,
        NULL AS parent_movie_id
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        mk.title AS movie_title,
        mk.production_year,
        mh.level + 1,
        mk.id AS movie_id,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mk ON ml.linked_movie_id = mk.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    mh.level,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN pi.info IS NOT NULL THEN LENGTH(pi.info) ELSE 0 END) AS avg_person_info_length,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS year_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
GROUP BY 
    mh.movie_title, mh.production_year, mh.level, ak.name
HAVING 
    COUNT(DISTINCT mc.company_id) > 0 AND 
    mh.level > 0 
ORDER BY 
    mh.production_year DESC, year_rank ASC;
