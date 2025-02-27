WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(mt.note, 'No Note') AS note,
        CAST(NULL AS INTEGER) AS parent_movie_id
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        COALESCE(at.note, 'No Note') AS note,
        mh.movie_id AS parent_movie_id
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mv.production_year,
    CASE 
        WHEN mv.kind_id IS NULL THEN 'Unknown Kind'
        ELSE kt.kind
    END AS movie_kind,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE 
            WHEN ci.note IS NOT NULL THEN 1 
            ELSE 0 
        END) AS cast_notes_count,
    AVG(CASE 
            WHEN ci.nag_order IS NULL OR ci.nag_order < 0 THEN 0 
            ELSE ci.nr_order 
        END) AS avg_order,
    COALESCE(STRING_AGG(DISTINCT mk.keyword, ', '), 'No Keywords') AS keywords
FROM cast_info ci
JOIN aka_name ak ON ci.person_id = ak.person_id
JOIN movie_hierarchy mv ON ci.movie_id = mv.movie_id 
LEFT JOIN movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN kind_type kt ON mv.kind_id = kt.id
GROUP BY ak.name, mv.title, mv.production_year, mv.kind_id
HAVING COUNT(DISTINCT mk.keyword) > 5
ORDER BY mv.production_year DESC, ak.name
LIMIT 100;

### Explanation:
- **CTE (`movie_hierarchy`)**: A recursive Common Table Expression that builds a hierarchy of movies. It starts with movies that have a production year and recursively finds linked movies.
- **Selection List**: 
  - Retrieves the actor's name, movie title, production year, and kind.
  - Utilizes a conditional to handle NULL values for `kind_id`.
  - Counts keywords associated with movies and counts non-null notes in the `cast_info` table.
  - Computes average order with NULL handling.
  - Aggregates keywords using `STRING_AGG`, addressing cases where there may be no keywords.
- **Joins**: 
  - Joins several tables, incorporating outer joins to include all movies even if they have no keywords.
- **HAVING Clause**: Ensures that only movies with more than five distinct keywords are retained in the results.
- **Order & Limit**: Results are ordered by production year in descending order, and a limit is placed on the number of results.
