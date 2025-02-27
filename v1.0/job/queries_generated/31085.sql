WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Only movies

    UNION ALL

    SELECT 
        lm.movie_id,
        lm.title,
        lm.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lm ON ml.linked_movie_id = lm.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(c.name, 'Unknown') AS company_name,
    ARRAY_AGG(DISTINCT ak.name) AS aka_names,
    COUNT(DISTINCT ci.person_id) AS num_actors,
    AVG(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') 
             THEN pi.info::numeric ELSE NULL END) AS avg_rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    mh.production_year BETWEEN 1990 AND 2023
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, c.name
ORDER BY 
    mh.production_year DESC, num_actors DESC, avg_rating DESC
LIMIT 100;
