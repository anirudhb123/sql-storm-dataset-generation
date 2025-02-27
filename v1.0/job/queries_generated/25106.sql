WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mv.linked_movie_id AS movie_id,
        l.movie_title,
        mv2.production_year,
        mh.level + 1
    FROM 
        movie_link mv
    JOIN 
        MovieHierarchy mh ON mv.movie_id = mh.movie_id
    JOIN 
        aka_title mv2 ON mv.linked_movie_id = mv2.id
)

SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    CASE 
        WHEN mh.level = 1 THEN 'Direct Movie'
        ELSE CONCAT('Linked Movie Level: ', mh.level)
    END AS movie_relation,
    t.production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(pi.info, 'N/A') AS actor_info
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title t ON mh.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
GROUP BY 
    ak.name, t.title, mh.level, t.production_year, pi.info
ORDER BY 
    t.production_year DESC, ak.name;
