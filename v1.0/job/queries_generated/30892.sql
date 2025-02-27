WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 1990 AND 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastRanking AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mt
    JOIN 
        keyword kt ON mt.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.total_cast, 0) AS total_cast,
    COALESCE(cr.avg_order, 0) AS avg_order,
    COALESCE(mg.genres, 'No Genres') AS genres,
    ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank_by_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastRanking cr ON mh.movie_id = cr.movie_id
LEFT JOIN 
    MovieGenres mg ON mh.movie_id = mg.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, mh.title;

This SQL query employs several advanced techniques, including:

1. **CTE (Common Table Expressions)**: It uses recursive CTEs to build a hierarchy of movies from 1990 to 2000 while also creating CTEs for calculating cast rankings and aggregating genres.

2. **LEFT JOINs**: The query left joins the `CastRanking` and `MovieGenres` CTEs to the main `MovieHierarchy` CTE to include casting information and genres.

3. **Aggregation**: It counts distinct cast members and calculates the average `nr_order`.

4. **STRING_AGG**: This function is used to concatenate multiple genre keywords into a single string for each movie.

5. **Window Function**: The query ranks movies by production year within their hierarchy level.

6. **NULL Handling**: It uses `COALESCE` to replace NULL values with defaults where necessary.

This results in a comprehensive view of movies within the specified years, their cast, and genre information, fully ranked, all while utilizing advanced SQL constructs.
