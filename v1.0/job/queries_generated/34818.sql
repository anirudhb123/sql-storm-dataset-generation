WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000  -- Filter for movies produced from 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    COALESCE(AVG(p.info::numeric), 0) AS average_rating,
    COUNT(DISTINCT mc.company_id) AS company_count,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS row_num
FROM 
    movie_hierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id 
LEFT JOIN 
    person_info p ON c.person_id = p.person_id AND p.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Rating'
    )
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 2  -- Movies must have more than 2 actors
ORDER BY 
    m.production_year DESC, m.title;
