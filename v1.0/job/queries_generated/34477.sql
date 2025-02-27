WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        CONCAT('Sequel to: ', m.title),
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_title,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    AVG(ki.score) AS average_keyword_score,
    ARRAY_AGG(DISTINCT c.kind) AS company_types,
    mh.production_year,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_type c ON c.id = mc.company_type_id
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(*) AS score
    FROM 
        movie_info
    WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        movie_id
) AS ki ON ki.movie_id = mh.movie_id
GROUP BY 
    mh.movie_title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    average_keyword_score DESC, 
    mh.production_year DESC;

