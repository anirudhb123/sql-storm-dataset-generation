WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.movie_id = at.id
    JOIN
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT COALESCE(ca.name, 'Unknown'), ', ') AS company_names,
    SUM(CASE 
            WHEN mw.kind IS NOT NULL THEN 1 
            ELSE 0 
        END) AS keyword_count,
    STRING_AGG(DISTINCT mw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mh.production_year DESC) AS row_rank
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
JOIN
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN
    company_name ca ON mc.company_id = ca.id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN
    keyword mw ON mk.keyword_id = mw.id
LEFT JOIN
    MovieHierarchy mh ON mh.movie_id = at.id
WHERE
    ak.name IS NOT NULL
    AND mh.level <= 3
    AND (at.production_year > 2000 OR at.kind_id IS NULL)
GROUP BY
    ak.name, at.title, mh.production_year
HAVING
    COUNT(DISTINCT mw.keyword) > 1
ORDER BY
    mh.production_year DESC,
    row_rank
OFFSET 10 ROWS
FETCH NEXT 20 ROWS ONLY;

This query utilizes various SQL features, including Common Table Expressions (CTEs) with recursion, outer joins, window functions, aggregated string functions (like `STRING_AGG`), and complex filtering logic. It provides insights into the relationships between movie titles, actors, associated production companies, and keywords in the given schema while observing some obscure edge cases with predicates and NULL handling.
