WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END) AS total_budget,
    MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre') THEN mi.info END) AS genre
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 AND 
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS INTEGER) ELSE 0 END) IS NOT NULL
ORDER BY 
    mh.production_year DESC, mh.level ASC;
