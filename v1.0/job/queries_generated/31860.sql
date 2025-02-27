WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level,
        m.production_year,
        NULL AS parent_movie_id
    FROM title m
    WHERE m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        mk.linked_movie_id AS movie_id,
        t.title,
        mh.level + 1 AS level,
        t.production_year,
        mh.movie_id AS parent_movie_id
    FROM movie_link mk
    JOIN title t ON mk.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON mk.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    mh.production_year,
    COALESCE(company.name, 'Unknown Company') AS production_company,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    AVG(pt.info) AS avg_rating
FROM MovieHierarchy mh
LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN company_name company ON mc.company_id = company.id
LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN person_info pi ON cc.subject_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        AVG(CAST(info AS DECIMAL)) AS info
    FROM movie_info
    WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY movie_id
) pt ON mh.movie_id = pt.movie_id
GROUP BY 
    mh.movie_id, 
    mh.title, 
    mh.level, 
    mh.production_year, 
    company.name
HAVING COUNT(DISTINCT ci.person_id) > 0
ORDER BY mh.production_year DESC, mh.level ASC;
