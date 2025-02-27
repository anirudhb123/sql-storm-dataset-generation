WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 -- Focus on more recent movies
    UNION ALL
    SELECT 
        lm.linked_movie_id,
        lm2.title,
        lm2.production_year,
        mh.depth + 1
    FROM 
        movie_link lm
    JOIN 
        movie_hierarchy mh ON lm.movie_id = mh.movie_id
    JOIN 
        aka_title lm2 ON lm.linked_movie_id = lm2.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(COALESCE(CAST(mi.info AS FLOAT), 0)) AS avg_movie_rating,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors_list
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id AND mc.company_type_id = (
        SELECT id FROM company_type WHERE kind = 'Production'
    )
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
ORDER BY 
    mh.production_year DESC, mh.depth ASC;
