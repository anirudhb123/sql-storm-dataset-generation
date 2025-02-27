WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::text AS parent_movie,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.title AS parent_movie,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_movie,
    mh.level,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(p.age) AS average_age,
    MAX(CASE WHEN c.note IS NOT NULL THEN c.note ELSE 'No Notes' END) AS latest_note
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
LEFT JOIN (
    SELECT 
        pi.person_id,
        EXTRACT(YEAR FROM AGE(CURRENT_DATE, pi.info::date)) AS age
    FROM 
        person_info pi
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
) p ON c.person_id = p.person_id
WHERE 
    mh.level <= 2
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.parent_movie, mh.level
ORDER BY 
    mh.level, mh.production_year DESC;
