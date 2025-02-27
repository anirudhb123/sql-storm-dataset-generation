WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        1 AS level,
        NULL::INTEGER AS parent_id
    FROM 
        title t
    JOIN 
        aka_title a ON t.id = a.movie_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    WHERE 
        t.production_year >= 2000
        AND mc.company_type_id = (SELECT id FROM company_type WHERE kind ILIKE 'Distributor')
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.level + 1,
        tt.episode_of_id
    FROM 
        MovieHierarchy mh
    JOIN 
        title tt ON mh.movie_id = tt.episode_of_id
    WHERE 
        tt.season_nr IS NOT NULL
)

SELECT 
    m.movie_id,
    m.movie_title,
    ARRAY_AGG(DISTINCT c.name) AS cast_names,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    COUNT(DISTINCT ci.company_id) AS company_count,
    MAX(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info ILIKE 'Rating') THEN pi.info END) AS movie_rating,
    MAX(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info ILIKE 'Duration') THEN pi.info END) AS movie_duration
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name c ON ci.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info pi ON pi.movie_id = m.movie_id
WHERE 
    m.level <= 5
GROUP BY 
    m.movie_id, m.movie_title
HAVING 
    COUNT(DISTINCT ci.person_id) > 10
    AND MAX(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info ILIKE 'Rating') THEN pi.info END) IS NOT NULL
ORDER BY 
    movie_rating DESC NULLS LAST
LIMIT 50;
