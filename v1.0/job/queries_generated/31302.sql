WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mv.id AS movie_id,
        mv.title,
        mv.production_year,
        mv.kind_id,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mv.title AS VARCHAR(255)) AS path
    FROM 
        movie_link ml
    JOIN 
        aka_title mv ON ml.linked_movie_id = mv.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    ci.nr_order AS cast_order,
    COALESCE(ci.note, 'No Note') AS cast_note,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS movie_rank,
    mh.path AS movie_path
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND (at.production_year > 2000 OR at.production_year IS NULL)
GROUP BY 
    ak.name, at.id, at.title, at.production_year, ci.nr_order, ci.note, mh.path
HAVING 
    COUNT(DISTINCT kw.id) > 1
ORDER BY 
    movie_rank, at.production_year DESC;

This SQL query implements multiple advanced SQL concepts including:
- A recursive CTE (`MovieHierarchy`) to build a hierarchy of linked movies.
- Various joins, including left joins to incorporate all relevant data from keywords.
- Coalesce for default values of notes.
- A window function (`ROW_NUMBER()`) for ranking movies per actor.
- Use of GROUP BY and HAVING clauses to filter results based on specific criteria.
- The use of string aggregation via `STRING_AGG` to concatenate keywords associated with movies.
- A complex WHERE condition that utilizes both existence checks and NULL logic.
