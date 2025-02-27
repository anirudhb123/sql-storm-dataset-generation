WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        title.kind_id,
        1 AS level
    FROM 
        title
    WHERE 
        production_year >= 2000  -- Starting point: Movies produced from 2000 onwards

    UNION ALL

    SELECT 
        title.id,
        title.title,
        title.production_year,
        title.kind_id,
        mh.level + 1
    FROM 
        title
    INNER JOIN movie_link ml ON ml.linked_movie_id = title.id
    INNER JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3  -- Limit the depth of recursion to avoid performance issues
),

KeywordMovie AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON k.id = mt.keyword_id
    GROUP BY 
        mt.movie_id
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(km.keywords, 'No Keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        KeywordMovie km ON mh.movie_id = km.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    CASE 
        WHEN md.rank <= 3 THEN 'Top 3 in category'
        ELSE 'Lower rank'
    END AS category_ranking
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2010 AND 2023
ORDER BY 
    md.kind_id, md.production_year DESC;

-- Additionally: Analyzing cast information
SELECT 
    c.movie_id,
    COUNT(DISTINCT ca.person_id) AS total_actors,
    AVG(COALESCE(ca.nr_order, 0)) AS avg_order
FROM 
    cast_info ca
JOIN 
    complete_cast c ON c.movie_id = ca.movie_id
GROUP BY 
    c.movie_id
HAVING 
    COUNT(DISTINCT ca.person_id) > 5  -- Only include movies with more than 5 actors
ORDER BY 
    total_actors DESC;

This query consists of several complex constructs:
- A **recursive CTE** (`MovieHierarchy`) to traverse movie relationships and create a hierarchy based on linked movies.
- A **string aggregation** function used to compile all keywords associated with movies in the `KeywordMovie` CTE.
- The **window function** `ROW_NUMBER()` in `MovieDetails` to rank movies by their production year within their kind.
- Use of **NULL logic** with `COALESCE` to provide default values when keywords are absent.
- A non-correlated second query analyzing cast information, demonstrating aggregate functions (`COUNT` and `AVG`) with grouping and filtering via the `HAVING` clause. 

This combination tests various SQL capabilities and can be used effectively for benchmarking performance across different querying strategies with joins and aggregations.
