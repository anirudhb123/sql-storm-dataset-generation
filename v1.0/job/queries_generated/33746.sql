WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        mh.level < 3  -- Limiting depth to avoid excessive recursion
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    AVG(CASE WHEN cc.note IS NULL THEN 0 ELSE 1 END) AS cast_present,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords

FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON mh.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND t.production_year >= 2000
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT cc.person_id) > 1
ORDER BY 
    total_cast DESC,
    t.production_year DESC
LIMIT 100;
This query performs a recursive Common Table Expression (CTE) to build a hierarchy of movies linked to each other, starting from movies produced after the year 2000. It then collects details regarding the actors (from the `aka_name` table), their associated movies, and aggregates information about the total cast and presence of notes, while also retrieving associated keywords. The results are grouped and filtered to show only those with a substantial cast involved in the production, sorted by the count of distinct cast members and production year.
