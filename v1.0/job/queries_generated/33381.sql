WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(cast_count.cast_count, 0) AS cast_count,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS cast_count 
        FROM 
            cast_info 
        GROUP BY 
            movie_id
    ) cast_count ON mt.id = cast_count.movie_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(cast_count.cast_count, 0) AS cast_count,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS cast_count 
        FROM 
            cast_info 
        GROUP BY 
            movie_id
    ) cast_count ON m.id = cast_count.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.cast_count,
    ROUND(AVG(mh.cast_count) OVER (PARTITION BY mh.production_year), 2) AS avg_cast_per_year,
    (CASE 
        WHEN mh.cast_count IS NULL THEN 'No Cast'
        WHEN mh.cast_count > 5 THEN 'Large Cast'
        WHEN mh.cast_count BETWEEN 1 AND 5 THEN 'Small Cast'
        ELSE 'No Data'
    END) AS cast_size_category
FROM 
    MovieHierarchy mh
ORDER BY 
    mh.production_year DESC, 
    mh.cast_count DESC
LIMIT 50;

This SQL query leverages a recursive Common Table Expression (CTE) to create a hierarchical view of linked movies while counting the number of cast members associated with each movie. It uses a window function to calculate the average number of cast members per production year and categorizes the cast size. The query handles NULL cases effectively and includes complex logic through the use of different SQL constructs, including joins, aggregates, and a CASE statement.
