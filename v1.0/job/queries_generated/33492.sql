WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM title t
    WHERE t.production_year >= 2000  -- Starting point for movies post-2000
    UNION ALL
    SELECT
        mt.linked_movie_id AS movie_id,
        th.title,
        th.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title th ON ml.linked_movie_id = th.id
    JOIN title mt ON th.id = mt.id
    WHERE mh.level < 3  -- Limiting the recursion to 3 levels
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS unnumbered_cast
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MovieDetails AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mc.total_cast,
        mc.unnumbered_cast,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS keyword_count
    FROM MovieHierarchy mh
    LEFT JOIN MovieCast mc ON mh.movie_id = mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.unnumbered_cast,
    md.keyword_count,
    COALESCE(CAST(md.total_cast AS FLOAT) / NULLIF(md.unnumbered_cast, 0), 0) AS cast_ratio,
    CASE 
        WHEN md.production_year < 2010 THEN 'Pre-2010'
        ELSE 'Post-2010'
    END AS period
FROM MovieDetails md
WHERE md.total_cast > 0
ORDER BY md.production_year DESC, md.keyword_count DESC;

This SQL query performs the following:

1. **Recursive CTE `MovieHierarchy`**: Builds a hierarchy of movies linked through the `movie_link` table starting from movies produced from the year 2000 onwards, limiting to a depth of 3.
   
2. **CTE `MovieCast`**: Aggregates information about the total number of cast members and counts how many of them are unnumbered for each movie.
   
3. **CTE `MovieDetails`**: Combines information from the `MovieHierarchy` and `MovieCast` to get movie titles, production years, total cast numbers, unnumbered casts, and the count of associated keywords for each movie.

4. **Final Selection**: The main query selects various attributes from the `MovieDetails`, calculating the ratio of total cast to unnumbered cast, while categorizing each movie into "Pre-2010" or "Post-2010" based on its production year.

5. **Sorting**: Results are ordered by the production year in descending order and by keyword count in descending order.

This generates a dataset useful for performance benchmarking based on movie attributes and their relations.
