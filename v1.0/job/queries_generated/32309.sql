WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth,
        m.imdb_id,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1,
        m.imdb_id,
        CAST(mh.path || ' > ' || m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5  -- limit recursion to avoid infinite loops
)

SELECT 
    a.name,
    mt.title,
    mt.production_year,
    COALESCE(CAST(COUNT(DISTINCT c.id) AS TEXT), '0') AS cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON mt.id = mh.movie_id
WHERE 
    a.name IS NOT NULL
    AND (mt.production_year >= 2000 OR mt.production_year IS NULL)
GROUP BY 
    a.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT c.id) > 0
ORDER BY 
    mt.production_year DESC, a.name;
