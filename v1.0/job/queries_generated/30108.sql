WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        lm.linked_movie_id,
        lm.linked_movie_id AS linked_movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link lm
    JOIN 
        MovieHierarchy mh ON lm.movie_id = mh.movie_id
    JOIN 
        aka_title m ON lm.linked_movie_id = m.id
)
SELECT 
    m.movie_id, 
    m.movie_title, 
    COALESCE(c.name, 'Unknown') AS company_name,
    COUNT(DISTINCT c.id) AS number_of_companies,
    AVG(cd.level) AS average_link_level,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    SUM(CASE 
        WHEN pi.info IS NOT NULL THEN 1 
        ELSE 0 
    END) AS person_infos_count
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id 
GROUP BY 
    m.movie_id, 
    m.movie_title, 
    company_name
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    number_of_companies DESC,
    average_link_level ASC;
