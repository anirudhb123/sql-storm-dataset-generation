WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS depth,
        ARRAY[t.id] AS path
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1,
        mh.path || m.id
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        NOT m.id = ANY(mh.path)  -- Prevent cycles in the hierarchy
),
AverageRating AS (
    SELECT 
        c.movie_id,
        AVG(r.rating) AS avg_rating
    FROM 
        complete_cast c
    JOIN 
        ratings r ON c.movie_id = r.movie_id
    GROUP BY 
        c.movie_id
),
CastCount AS (
    SELECT 
        movie_id,
        COUNT(*) AS cast_count
    FROM 
        cast_info 
    GROUP BY 
        movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ar.avg_rating,
        cc.cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY ar.avg_rating DESC) AS row_num
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AverageRating ar ON mh.movie_id = ar.movie_id
    LEFT JOIN 
        CastCount cc ON mh.movie_id = cc.movie_id
    WHERE 
        ar.avg_rating IS NOT NULL AND
        cc.cast_count > 0
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.avg_rating, 0) AS avg_rating,
    fm.cast_count,
    mh.depth
FROM 
    FilteredMovies fm
JOIN 
    MovieHierarchy mh ON fm.movie_id = mh.movie_id
WHERE 
    fm.row_num <= 10
ORDER BY 
    fm.production_year DESC, 
    fm.avg_rating DESC,
    fm.cast_count DESC;


### Explanation:
1. **MovieHierarchy**: This recursive CTE generates a hierarchical structure of movies and their linked films. It prevents cycles by using a path array.
2. **AverageRating**: This CTE computes the average rating of each movie based on the `complete_cast` linked to the `ratings` table.
3. **CastCount**: This CTE counts the number of cast members associated with each movie.
4. **FilteredMovies**: This CTE combines data from previous CTEs, filtering out movies without ratings or cast members. It ranks movies by rating within each production year.
5. The final query selects the top 10 movies by average rating per production year, displaying relevant information and including NULL handling for the rating.
