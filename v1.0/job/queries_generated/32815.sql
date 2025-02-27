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
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT
    a.id AS aka_id,
    a.name AS aka_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    COALESCE(person.name, 'Unknown') AS person_name,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS name_rank,
    COUNT(DISTINCT mc.company_id) OVER (PARTITION BY t.id) AS company_count,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = t.id) AS cast_count,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = t.id) AS keywords
FROM
    aka_name a
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title t ON ci.movie_id = t.id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_type c ON mc.company_type_id = c.id
LEFT JOIN
    name person ON ci.person_id = person.imdb_id
WHERE
    t.production_year >= 2000
    AND COALESCE(c.kind, 'No Company') <> 'No Company'
    AND EXISTS (SELECT 1 FROM MovieHierarchy mh WHERE mh.movie_id = t.id)
ORDER BY
    t.production_year DESC, a.name;
