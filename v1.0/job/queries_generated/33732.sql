WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy h ON ml.movie_id = h.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    mh.movie_id, 
    mh.title AS movie_title,
    mh.production_year,
    COALESCE(CHAR_LENGTH(mh.title) - CHAR_LENGTH(REPLACE(mh.title, ' ', '')), 0) + 1 AS word_count,
    c.role AS cast_role,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS period,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT m.movie_id) OVER (PARTITION BY mh.movie_id) AS total_links
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    mh.movie_id, 
    ak.name, 
    c.role, 
    mh.title, 
    mh.production_year
ORDER BY 
    mh.production_year DESC, 
    COUNT(DISTINCT k.keyword) DESC;

