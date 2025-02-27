WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    COALESCE(n.name, 'Unknown') AS actor_name,
    title.title AS movie_title,
    title.production_year,
    STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(CASE 
            WHEN ci.note IS NOT NULL THEN LENGTH(ci.note)
            ELSE 0 
        END) AS avg_note_length,
    COUNT(DISTINCT CASE 
            WHEN mi.info_type_id IS NOT NULL THEN m.id 
            ELSE NULL 
        END) AS total_info_type_entries
FROM 
    cast_info ci
JOIN 
    aka_name n ON ci.person_id = n.person_id
JOIN 
    aka_title title ON ci.movie_id = title.id
LEFT JOIN 
    movie_keyword mk ON title.id = mk.movie_id
LEFT JOIN 
    keyword ON mk.keyword_id = keyword.id
LEFT JOIN 
    movie_info mi ON title.id = mi.movie_id
LEFT JOIN 
    MovieHierarchy mh ON title.id = mh.movie_id
WHERE 
    title.production_year IS NOT NULL
GROUP BY 
    actor_name, title.title, title.production_year
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 3
ORDER BY 
    title.production_year DESC, actor_name
LIMIT 50;

