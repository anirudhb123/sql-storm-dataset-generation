WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.imdb_index,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT
        m.id,
        m.title,
        m.production_year,
        m.imdb_index,
        depth + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    SUM(mk.count) AS keyword_count,
    MAX(COALESCE(mk.info, 'No Keywords')) AS keyword_info,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS ranking
FROM
    MovieHierarchy mh
LEFT JOIN
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN (
    SELECT
        mk.movie_id, 
        COUNT(*) AS count,
        STRING_AGG(k.keyword, ', ') AS info
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
) mk ON mh.movie_id = mk.movie_id
WHERE
    mh.production_year >= 1990
GROUP BY
    mh.movie_id, mh.movie_title, mh.production_year
ORDER BY
    mh.production_year, actor_count DESC
FETCH FIRST 100 ROWS ONLY;

### Query Explanation:
- **Recursive CTE (`WITH RECURSIVE`):** This builds a hierarchy from the `aka_title` table to find all movies and their linked titles recursively.
- **Aggregation:** The main query aggregates data, counting actors in `cast_info` and concatenating actor names.
- **Keyword Info:** A subquery counts and aggregates keywords associated with each movie.
- **`COALESCE`:** This is used to handle NULL values by providing a default string when there are no keywords.
- **Window Function:** `ROW_NUMBER()` ranks movies by actor count within their production year.
- **Filtering and Fetching:** The `WHERE` clause restricts results to movies from 1990 onwards, and `FETCH FIRST 100 ROWS ONLY` limits the results returned.
