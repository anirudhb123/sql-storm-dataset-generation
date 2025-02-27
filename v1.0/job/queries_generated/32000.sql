WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        linked_movie.linked_movie_id AS movie_id,
        mk.title,
        mk.production_year,
        mh.depth + 1
    FROM 
        movie_link linked_movie
    JOIN 
        MovieHierarchy mh ON linked_movie.movie_id = mh.movie_id
    JOIN 
        aka_title mk ON linked_movie.linked_movie_id = mk.id
)
SELECT 
    m.title,
    m.production_year,
    ak.name AS actor_name,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(mv.info_length) AS avg_info_length,
    MAX(mv.note) AS last_note,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    (SELECT 
         mi.movie_id,
         LENGTH(mi.info) AS info_length,
         MAX(mi.note) AS note
     FROM 
         movie_info mi
     GROUP BY 
         mi.movie_id) mv ON m.movie_id = mv.movie_id
WHERE 
    m.production_year IS NOT NULL
    AND m.title IS NOT NULL
GROUP BY 
    m.movie_id, ak.name, m.title, m.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 5
ORDER BY 
    m.production_year DESC, keyword_count DESC;
