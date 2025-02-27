WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mc.linked_movie_id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        mh.depth + 1
    FROM 
        movie_link mc
    JOIN 
        title t ON t.id = mc.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    AVG(CASE WHEN mi.info IS NOT NULL THEN CAST(mi.info AS numeric) ELSE NULL END) AS average_rating,
    NULLIF(MAX(CASE WHEN ck.keyword IS NOT NULL THEN ck.keyword END), '') AS first_keyword,
    STRING_AGG(DISTINCT cn.name, '; ') AS company_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info c ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword ck ON ck.id = mk.keyword_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    mh.production_year DESC, total_cast DESC;
