WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(MH.level, 0) AS hierarchy_level,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(pi.info) FILTER (WHERE pi.info_type_id = 2) AS avg_person_age,
    STRING_AGG(DISTINCT ckt.kind ORDER BY ckt.kind) AS company_kinds,
    SUM(CASE 
            WHEN c.note IS NULL THEN 1
            ELSE 0 
        END) AS null_notes_count
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    MovieHierarchy MH ON at.id = MH.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    movie_info pi ON at.id = pi.movie_id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_type ckt ON mc.company_type_id = ckt.id
WHERE 
    ak.name IS NOT NULL
    AND at.production_year BETWEEN 2000 AND 2023
    AND (c.role_id < 10 OR c.note IS NULL)
GROUP BY 
    ak.name, at.title, hierarchy_level
ORDER BY 
    keyword_count DESC, avg_person_age DESC NULLS LAST
LIMIT 50;
