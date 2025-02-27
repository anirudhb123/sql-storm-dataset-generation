WITH RecursiveCast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),

MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ka.name, 'Unknown') AS main_actor,
        rc.distinct_cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS movie_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_name ka ON mt.id = ka.id
    LEFT JOIN 
        RecursiveCast rc ON mt.id = rc.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),

FilteredMovies AS (
    SELECT
        md.*,
        CASE 
            WHEN md.production_year < 2000 THEN 'Classic'
            WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era_category
    FROM
        MovieDetails md
    WHERE 
        md.distinct_cast_count IS NOT NULL
        AND md.production_year >= 1980
),

TopMovies AS (
    SELECT 
        era_category,
        AVG(distinct_cast_count) as avg_cast_count,
        COUNT(*) as movie_count
    FROM 
        FilteredMovies
    GROUP BY 
        era_category
)

SELECT 
    t.era_category,
    t.avg_cast_count,
    t.movie_count,
    GROUP_CONCAT(md.title) AS movie_titles
FROM 
    TopMovies t
LEFT JOIN 
    FilteredMovies md ON t.era_category = md.era_category
GROUP BY 
    t.era_category, t.avg_cast_count, t.movie_count
ORDER BY 
    t.avg_cast_count DESC;

WITH AllMovieLinks AS (
    SELECT 
        ml.movie_id,
        COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count,
        (SELECT COUNT(*) FROM movie_link WHERE movie_id = ml.movie_id) as total_links
    FROM 
        movie_link ml
    GROUP BY 
        ml.movie_id
)

SELECT 
    a.movie_id,
    a.linked_movies_count,
    a.total_links,
    CASE 
        WHEN a.linked_movies_count = 0 THEN 'No Links'
        WHEN a.linked_movies_count > a.total_links THEN 'Inconsistent'
        ELSE 'Normal'
    END AS link_status
FROM 
    AllMovieLinks a
WHERE 
    a.total_links IS NOT NULL
ORDER BY
    a.movie_id;

SELECT 
    mt.title,
    mt.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    SUM(CASE WHEN ci.role_id IS NULL THEN 0 ELSE 1 END) AS role_count,
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY mt.id) AS cast_members_count
FROM 
    aka_title mt
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    cast_info ci ON mt.id = ci.movie_id
GROUP BY 
    mt.title, mt.production_year, mk.keyword
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    mt.production_year DESC, mt.title;

This SQL query includes multiple CTEs to structure the different parts of the data retrieval for benchmarking purposes, utilizing various SQL features such as outer joins, aggregate functions, window functions, and conditional logic. Additionally, it ranks movies by various attributes, filters based on distinct counts, and employs recursive common table expressions to enrich the analysis of cast and connection data.
