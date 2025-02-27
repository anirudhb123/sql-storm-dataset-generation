WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
, MovieInfoWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.id
)
, CastAggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') FILTER (WHERE ci.person_role_id IS NOT NULL) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mi.keywords, 'No Keywords') AS keywords,
    COALESCE(ca.total_cast, 0) AS total_cast,
    COALESCE(ca.cast_names, 'No Cast') AS cast_names,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieInfoWithKeywords mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    CastAggregates ca ON mh.movie_id = ca.movie_id
WHERE 
    mh.depth < 4
    AND (mi.keywords IS NOT NULL OR ca.total_cast > 0)
ORDER BY 
    mh.production_year DESC,
    mh.title;

### Explanation of the Query:

1. **CTE MovieHierarchy**: Creates a recursive common table expression to build a hierarchy of movies from the `aka_title` table. It starts with movies released after 2000 and tracks their linked movies recursively.

2. **CTE MovieInfoWithKeywords**: Aggregates keywords associated with the movies by joining the movie_keyword and keyword tables, delivering a single string containing all keywords for each movie.

3. **CTE CastAggregates**: Counts distinct cast members for each movie and aggregates their names into a string, filtered by available roles.

4. **Main SELECT Statement**: 
   - Selects data from the `MovieHierarchy` CTE and joins it with the MovieInfoWithKeywords and CastAggregates, allowing for outer joins to account for movies without keywords or cast.
   - The `COALESCE` function is used to handle NULLs, providing default messages for cases where there are no keywords or no cast members.
   - The `WHERE` clause restricts the results to movies that are either linked to another movie or have keywords.
   - Finally, results are ordered by production year (most recent first) and title alphabetically. 

This architecture allows for in-depth performance benchmarking of querying complex hierarchical relationships, aggregation, and handling of NULLs in SQL.
