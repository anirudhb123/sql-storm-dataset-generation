WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        mn.id AS movie_id,
        mn.title AS movie_title,
        mn.production_year,
        mn.kind_id,
        mh.level + 1
    FROM 
        aka_title mn
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = mn.episode_of_id
)

SELECT 
    a.name AS actor_name,
    a.surname_pcode AS actor_surname_pcode,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT c.id) AS total_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY a.name) AS actor_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
AND 
    (mh.production_year IS NOT NULL OR mh.kind_id IS NULL)
GROUP BY 
    a.id, mh.movie_id, mh.movie_title, mh.production_year, a.surname_pcode
HAVING 
    COUNT(DISTINCT c.id) > 1
ORDER BY 
    mh.production_year DESC,
    actor_rank ASC;
