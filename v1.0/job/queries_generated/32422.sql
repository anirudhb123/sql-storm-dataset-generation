WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.movie_id = at.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    mh.level AS movie_hierarchy_level,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY mt.id) AS total_actors,
    AVG(CASE 
        WHEN pi.info LIKE '%award%' THEN 1 
        ELSE 0 
    END) OVER (PARTITION BY mt.id) AS avg_award_nomination,
    COALESCE((
        SELECT 
            COUNT(DISTINCT mk.keyword_id)
        FROM 
            movie_keyword mk
        WHERE 
            mk.movie_id = mt.id
    ), 0) AS total_keywords,
    CASE 
        WHEN ct.kind IS NOT NULL THEN ct.kind 
        ELSE 'Unknown' 
    END AS company_type
FROM 
    MovieHierarchy mh
INNER JOIN 
    aka_title mt ON mh.movie_id = mt.id
LEFT JOIN 
    complete_cast cc ON mt.id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
WHERE 
    mt.production_year >= 2000
    AND ak.name IS NOT NULL
ORDER BY 
    mt.production_year DESC, mh.level ASC;
