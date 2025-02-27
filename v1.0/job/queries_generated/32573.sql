WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year >= 2000
)

SELECT 
    a.name AS actor_name,
    am.movie_title,
    am.production_year,
    COUNT(DISTINCT ak.id) AS associated_keywords,
    RANK() OVER (PARTITION BY am.actor_id ORDER BY am.production_year DESC) AS rank_in_production,
    COALESCE(NULLIF(am.note, ''), 'No additional notes') AS note_info,
    string_agg(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title am ON mh.movie_id = am.id
LEFT JOIN 
    movie_keyword mk ON am.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND am.production_year >= 2000
    AND (a.md5sum IS NOT NULL OR am.note IS NULL)
GROUP BY 
    a.name, am.movie_title, am.production_year, am.note
ORDER BY 
    actor_name, production_year;

In this query:
- A recursive common table expression (CTE) (`MovieHierarchy`) is created to explore the hierarchy of movies linked to one another.
- The main query pulls data from several tables, including `aka_name`, `cast_info`, and `aka_title`.
- It gathers additional metrics like the count of associated keywords and utilizes a window function (`RANK()`) to rank movies for each actor by their production year.
- It employs aggregate functions like `string_agg` to collect keywords into a single string.
- The query includes NULL logic checks and ensures to filter out records accordingly.
